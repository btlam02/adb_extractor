import os
import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import hashlib


def run_adb_command(command):
    try:
        result = subprocess.check_output(command, shell=True, text=True)
        return result.strip()
    except subprocess.CalledProcessError as e:
        return str(e)

def get_installed_packages():
    output = run_adb_command("adb shell pm list packages")
    return [line.replace("package:", "") for line in output.split('\n') if line]

def is_device_rooted():
    result = run_adb_command("adb shell su -c 'echo rooted'")
    return "rooted" in result


def calculate_sha256(file_path):
    sha256_hash = hashlib.sha256()
    try:
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    except Exception as e:
        return str(e)

def extract_data(package_name, save_path, extract_types):
    success_list, fail_list = [], []
    
    # Public Data Extraction
    if "public" in extract_types:
        remote_tar_public = f"/storage/emulated/0/{package_name}_public_data.tar.gz"
        local_tar_public = os.path.join(save_path, f"{package_name}_public_data.tar.gz")
        tar_command_public = f"adb shell tar -czf {remote_tar_public} -C /storage/emulated/0/Android/data/{package_name} ."
        
        run_adb_command(tar_command_public)
        run_adb_command(f"adb pull {remote_tar_public} {local_tar_public}")

        if os.path.exists(local_tar_public):
            # Calculate SHA256 for public data
            public_sha256 = calculate_sha256(local_tar_public)
            with open(os.path.join(save_path, f"{package_name}_public_data_hash.txt"), "w") as hash_file:
                hash_file.write(f"SHA256: {public_sha256}")
            success_list.append("Public Data")
        else:
            fail_list.append("Public Data")
    
    # Private Data Extraction (requires root)
    if "private" in extract_types:
        if not is_device_rooted():
            messagebox.showerror("Error", "Device is not rooted. Private data extraction requires root access.")
            fail_list.append("Private Data")
        else:
            remote_tar_private = f"/data/local/tmp/{package_name}_private_data.tar.gz"
            local_tar_private = os.path.join(save_path, f"{package_name}_private_data.tar.gz")
            tar_command_private = f"adb shell su -c 'tar -czf {remote_tar_private} -C /data/data/{package_name} .'"
            
            run_adb_command(tar_command_private)
            run_adb_command(f"adb pull {remote_tar_private} {local_tar_private}")

            if os.path.exists(local_tar_private):
                # Calculate SHA256 for private data
                private_sha256 = calculate_sha256(local_tar_private)
                with open(os.path.join(save_path, f"{package_name}_private_data_hash.txt"), "w") as hash_file:
                    hash_file.write(f"SHA256: {private_sha256}")
                success_list.append("Private Data")
            else:
                fail_list.append("Private Data")

    # Show the result of the extraction
    message = ""
    if success_list:
        message += f"✅ Successfully extracted: {', '.join(success_list)}.\n"
    if fail_list:
        message += f"❌ Failed to extract: {', '.join(fail_list)}.\n"
    
    if message:
        messagebox.showinfo("Extraction Result", message)

def start_extraction():
    selected_index = package_listbox.curselection()
    if not selected_index:
        messagebox.showwarning("Warning", "Please select a package")
        return
    
    package_name = package_listbox.get(selected_index)
    save_path = filedialog.askdirectory(title="Select Save Location")
    if not save_path:
        return
    
    extract_types = []
    if public_var.get():
        extract_types.append("public")
    if private_var.get():
        extract_types.append("private")
    
    if not extract_types:
        messagebox.showwarning("Warning", "Please select at least one data type to extract")
        return
    
    extract_data(package_name, save_path, extract_types)

# GUI Setup
root = tk.Tk()
root.title("ADB Data Extractor")
root.geometry("450x500")
root.resizable(False, False)
root.configure(bg="#f5f5f5")

# Title
title_label = tk.Label(root, text="ADB Data Extractor", font=("Arial", 14, "bold"), bg="#f5f5f5")
title_label.pack(pady=15)

# Frame for Listbox
frame = tk.Frame(root)
frame.pack(pady=5, fill=tk.BOTH, expand=True)

# Scrollable Listbox for Packages
package_listbox = tk.Listbox(frame, height=10, width=50, selectmode=tk.SINGLE)
scrollbar = tk.Scrollbar(frame, orient=tk.VERTICAL, command=package_listbox.yview)
package_listbox.config(yscrollcommand=scrollbar.set)

# Populate Listbox
packages = get_installed_packages()
for pkg in packages:
    package_listbox.insert(tk.END, pkg)

package_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

# Data Type Selection
tk.Label(root, text="Select Data Types:", bg="#f5f5f5", font=("Arial", 10)).pack()
public_var = tk.BooleanVar()
private_var = tk.BooleanVar()
tk.Checkbutton(root, text="Public Data", variable=public_var, bg="#f5f5f5").pack()
tk.Checkbutton(root, text="Private Data (Root Required)", variable=private_var, bg="#f5f5f5").pack()

# Extract Button
extract_button = tk.Button(root, text="Extract Data", command=start_extraction, font=("Arial", 12, "bold"), bg="#4CAF50", fg="white", padx=10, pady=5)
extract_button.pack(pady=10)

root.mainloop()