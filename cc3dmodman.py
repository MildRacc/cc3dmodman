import os
import shutil
import subprocess
import tempfile
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import zipfile
import json

APP_NAME = "Crazy Cattle 3D Mod Loader"
MODS_DIR = "mods"
GODOTPCKTOOL_PATH = "./godotpcktool"
CC3DMODMAN_DIR = "./cc3dmodman"


class Mod:
    def __init__(self, name:  str, path: str, is_zip: bool = False):
        self.name = name
        self.path = path
        self.is_zip = is_zip
        self.enabled = True
        self.description = ""
        self.author = ""
        self.version = ""
        self.load_metadata()

    def load_metadata(self):
        """Load mod.json metadata if it exists."""
        try:
            if self.is_zip:
                with zipfile.ZipFile(self.path, 'r') as z:
                    # Look for mod.json in the zip
                    for name in z.namelist():
                        if name.endswith('mod.json'):
                            with z.open(name) as f:
                                data = json.loads(f.read().decode('utf-8'))
                                self._parse_metadata(data)
                            break
            else:
                mod_json_path = os.path.join(self.path, "mod.json")
                if os.path.exists(mod_json_path):
                    with open(mod_json_path, 'r') as f:
                        data = json.load(f)
                        self._parse_metadata(data)
        except Exception as e:
            print(f"[WARNING] Could not load metadata for {self.name}: {e}")

    def _parse_metadata(self, data: dict):
        self.description = data.get("description", "")
        self.author = data.get("author", "")
        self.version = data.get("version", "")
        if "name" in data:
            self.name = data["name"]


class ModLoader:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title(APP_NAME)
        self.root.geometry("650x800")
        self.root.resizable(True, True)

        self.executable_path = None
        self.pck_path = None
        self.mods: list[Mod] = []
        self.mod_vars: dict[str, tk.BooleanVar] = {}

        self.setup_ui()
        self.scan_mods()

    def setup_ui(self):
        # Title
        title_frame = tk.Frame(self.root)
        title_frame.pack(fill=tk.X, padx=10, pady=10)

        tk.Label(
            title_frame,
            text="🐑 " + APP_NAME + " 🐑",
            font=("Arial", 18, "bold")
        ).pack()

        # Mods Section
        mods_frame = tk.LabelFrame(self.root, text="Available Mods", font=("Arial", 11))
        mods_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)

        # Scrollable mod list
        canvas = tk.Canvas(mods_frame)
        scrollbar = ttk.Scrollbar(mods_frame, orient="vertical", command=canvas.yview)
        self.mods_inner_frame = tk.Frame(canvas)

        self.mods_inner_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=self.mods_inner_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Bind mousewheel
        canvas.bind_all("<MouseWheel>", lambda e: canvas.yview_scroll(int(-1*(e.delta/120)), "units"))

        # Buttons for mod management
        mod_buttons_frame = tk.Frame(self.root)
        mod_buttons_frame.pack(fill=tk.X, padx=10, pady=5)

        tk.Button(
            mod_buttons_frame,
            text="↻ Refresh Mods",
            command=self.scan_mods
        ).pack(side=tk.LEFT, padx=2)

        tk.Button(
            mod_buttons_frame,
            text="✓ Select All",
            command=self.select_all_mods
        ).pack(side=tk.LEFT, padx=2)

        tk.Button(
            mod_buttons_frame,
            text="✗ Deselect All",
            command=self.deselect_all_mods
        ).pack(side=tk.LEFT, padx=2)

        tk.Button(
            mod_buttons_frame,
            text="📁 Open Mods Folder",
            command=self.open_mods_folder
        ).pack(side=tk.RIGHT, padx=2)

        # Separator
        ttk.Separator(self.root, orient='horizontal').pack(fill=tk.X, padx=10, pady=10)

        # Game Selection
        game_frame = tk.LabelFrame(self.root, text="Game", font=("Arial", 11))
        game_frame.pack(fill=tk.X, padx=10, pady=5)

        self.executable_label = tk.Label(
            game_frame,
            text="No game selected",
            wraplength=400,
            fg="gray"
        )
        self.executable_label.pack(pady=5)

        tk.Button(
            game_frame,
            text="📂 Select Game Executable",
            command=self.select_executable
        ).pack(pady=5)

        # Launch Button
        self.launch_button = tk.Button(
            self.root,
            text="Launch Modded Game",
            font=("Arial", 14, "bold"),
            bg="#4CAF50",
            fg="white",
            height=2,
            command=self.inject_and_run,
            state=tk.DISABLED
        )
        self.launch_button.pack(fill=tk.X, padx=10, pady=10)

        # Status Bar
        self.status_label = tk.Label(
            self.root,
            text="Ready",
            fg="gray",
            anchor="w"
        )
        self.status_label.pack(fill=tk.X, padx=10, pady=5)

    def scan_mods(self):
        """Scan the Mods directory for available mods."""
        self.mods.clear()
        self.mod_vars.clear()

        # Clear existing mod widgets
        for widget in self.mods_inner_frame.winfo_children():
            widget.destroy()

        if not os.path.exists(MODS_DIR):
            os.makedirs(MODS_DIR)
            tk.Label(
                self.mods_inner_frame,
                text="No mods found.\nAdd mods to the 'Mods' folder.",
                fg="gray"
            ).pack(pady=20)
            self.set_status(f"Created Mods folder. Add mods to get started.")
            return

        # Scan for mods (folders and zips)
        items = os.listdir(MODS_DIR)
        for item in items:
            item_path = os.path.join(MODS_DIR, item)

            if os.path.isdir(item_path):
                # Check if it has main.gd or preload.gd
                has_main = os.path.exists(os.path.join(item_path, "main.gd"))
                has_preload = os.path.exists(os.path.join(item_path, "preload.gd"))
                if has_main or has_preload:
                    self.mods.append(Mod(item, item_path, is_zip=False))

            elif item.endswith('.zip'):
                # Check if zip contains a mod
                try:
                    with zipfile.ZipFile(item_path, 'r') as z:
                        names = z.namelist()
                        has_main = any('main.gd' in n for n in names)
                        has_preload = any('preload.gd' in n for n in names)
                        if has_main or has_preload:
                            mod_name = item[:-4]  # Remove .zip
                            self.mods.append(Mod(mod_name, item_path, is_zip=True))
                except zipfile.BadZipFile:
                    print(f"[WARNING] Invalid zip file: {item}")

        if not self.mods:
            tk.Label(
                self.mods_inner_frame,
                text="No mods found.\nAdd mod folders or .zip files to the 'Mods' folder.",
                fg="gray"
            ).pack(pady=20)
            self.set_status("No mods found")
            return

        # Create checkboxes for each mod
        for mod in self.mods:
            self.create_mod_widget(mod)

        self.set_status(f"Found {len(self.mods)} mod(s)")

    def create_mod_widget(self, mod:  Mod):
        """Create a widget for a single mod."""
        frame = tk.Frame(self.mods_inner_frame, relief=tk.RIDGE, borderwidth=1)
        frame.pack(fill=tk.X, padx=5, pady=3)

        # Checkbox
        var = tk.BooleanVar(value=True)
        self.mod_vars[mod.name] = var

        checkbox = tk.Checkbutton(
            frame,
            variable=var,
            command=lambda m=mod, v=var: setattr(m, 'enabled', v.get())
        )
        checkbox.pack(side=tk.LEFT, padx=5)

        # Mod info
        info_frame = tk.Frame(frame)
        info_frame.pack(side=tk.LEFT, fill=tk.X, expand=True, pady=5)

        # Name and version
        name_text = mod.name
        if mod.version:
            name_text += f" v{mod.version}"
        if mod.is_zip:
            name_text += " 📦"

        tk.Label(
            info_frame,
            text=name_text,
            font=("Arial", 10, "bold"),
            anchor="w"
        ).pack(fill=tk.X)

        # Author
        if mod.author:
            tk.Label(
                info_frame,
                text=f"by {mod.author}",
                font=("Arial", 8),
                fg="gray",
                anchor="w"
            ).pack(fill=tk.X)

        # Description
        if mod.description:
            tk.Label(
                info_frame,
                text=mod.description,
                font=("Arial", 9),
                fg="#555",
                anchor="w",
                wraplength=350,
                justify=tk.LEFT
            ).pack(fill=tk.X)

    def select_all_mods(self):
        for var in self.mod_vars.values():
            var.set(True)
        for mod in self.mods:
            mod.enabled = True

    def deselect_all_mods(self):
        for var in self.mod_vars.values():
            var.set(False)
        for mod in self.mods:
            mod.enabled = False

    def open_mods_folder(self):
        if not os.path.exists(MODS_DIR):
            os.makedirs(MODS_DIR)

        # Cross-platform folder opening
        if os.name == 'nt':   # Windows
            os.startfile(MODS_DIR)
        elif os.name == 'posix':  # Linux/Mac
            subprocess.run(['xdg-open', MODS_DIR])

    def select_executable(self):
        executable = filedialog.askopenfilename(
            title="Select Crazy Cattle 3D Executable",
            filetypes=[
                ("Linux Executable", "*.x86_64"),
                ("Windows Executable", "*.exe"),
                ("All files", "*.*")
            ],
        )
        if executable:
            self.executable_path = executable
            self.detect_pck_file()
            if self.pck_path:
                self.executable_label.config(
                    text=f"✓ {os.path.basename(executable)}",
                    fg="green"
                )
                self.launch_button.config(state=tk.NORMAL)
                self.set_status("Game selected. Ready to launch!")

    def detect_pck_file(self):
        exec_dir = os.path.dirname(self.executable_path)
        for file in os.listdir(exec_dir):
            if file.endswith(".pck"):
                self.pck_path = os.path.join(exec_dir, file)
                return
        messagebox.showerror("Error", f"No .pck file found in {exec_dir}.")
        self.set_status("Error: No .pck file found", "red")
        self.pck_path = None

    def set_status(self, text: str, color: str = "gray"):
        self.status_label.config(text=text, fg=color)

    def extract_zip_mod(self, mod:  Mod, dest_dir: str):
        """Extract a zipped mod to the destination directory."""
        with zipfile.ZipFile(mod.path, 'r') as z:
            # Find the root folder in the zip
            names = z.namelist()

            # Check if files are in a subfolder
            root_folder = None
            for name in names:
                if '/' in name:
                    potential_root = name.split('/')[0]
                    if any(n.startswith(potential_root + '/') for n in names):
                        root_folder = potential_root
                        break

            if root_folder:
                # Extract and rename to mod name
                z.extractall(dest_dir)
                extracted_path = os.path.join(dest_dir, root_folder)
                final_path = os.path.join(dest_dir, mod.name)
                if extracted_path != final_path:
                    if os.path.exists(final_path):
                        shutil.rmtree(final_path)
                    os.rename(extracted_path, final_path)
            else:
                # Files are at root level, extract to mod name folder
                mod_folder = os.path.join(dest_dir, mod.name)
                os.makedirs(mod_folder, exist_ok=True)
                z.extractall(mod_folder)

    def inject_and_run(self):
        if not self.pck_path or not self.executable_path:
            messagebox.showerror("Error", "Please select a game executable first.")
            return

        enabled_mods = [m for m in self.mods if m.enabled]
        if not enabled_mods:
            messagebox.showwarning("Warning", "No mods selected!")
            return

        if not os.path.exists(GODOTPCKTOOL_PATH):
            messagebox.showerror("Error", "GodotPckTool not found!")
            return

        if not os.path.exists(CC3DMODMAN_DIR):
            messagebox.showerror("Error", "cc3dmodman folder not found!")
            return

        self.set_status("Preparing modded game...", "blue")
        self.root.update()

        with tempfile.TemporaryDirectory() as tmpdir:
            # Determine temporary executable name based on OS
            if self.executable_path.endswith(".exe"):
                modded_executable = os.path.join(tmpdir, "CrazyCattle3D_Mod.exe")
            else:
                modded_executable = os.path.join(tmpdir, "CrazyCattle3D_Mod.x86_64")

            modded_pck = os.path.join(tmpdir, "CrazyCattle3D_Mod.pck")
            extracted_dir = os.path.join(tmpdir, "extracted")

            shutil.copy(self.executable_path, modded_executable)

            # Extract the .pck
            self.set_status("Extracting game files...", "blue")
            self.root.update()
            subprocess.run(
                [GODOTPCKTOOL_PATH, self.pck_path, "-a", "e", "-o", extracted_dir],
                capture_output=True
            )

            # Remove compiled node.gd files if present
            for filename in ["node.gdc", "node.gd.remap"]:
                filepath = os.path.join(extracted_dir, filename)
                if os.path.exists(filepath):
                    os.remove(filepath)

            # Copy cc3dmodman files
            self.set_status("Installing mod framework...", "blue")
            self.root.update()
            for item in os.listdir(CC3DMODMAN_DIR):
                src = os.path.join(CC3DMODMAN_DIR, item)
                dest = os.path.join(extracted_dir, item)
                if os.path.isfile(src) and src.endswith(".gd"):
                    shutil.copy(src, dest)
                elif os.path.isdir(src):
                    if os.path.exists(dest):
                        shutil.rmtree(dest)
                    shutil.copytree(src, dest)

            # Copy enabled mods
            mods_dest = os.path.join(extracted_dir, "mods")
            os.makedirs(mods_dest, exist_ok=True)

            for mod in enabled_mods:
                self.set_status(f"Installing mod: {mod.name}...", "blue")
                self.root.update()

                if mod.is_zip:
                    self.extract_zip_mod(mod, mods_dest)
                else:
                    dest = os.path.join(mods_dest, mod.name)
                    shutil.copytree(mod.path, dest)

                print(f"[DEBUG] Added mod: {mod.name}")

            # Build new .pck
            self.set_status("Building modded game...", "blue")
            self.root.update()
            subprocess.run(
                [GODOTPCKTOOL_PATH, modded_pck, "-a", "a", extracted_dir,
                "--remove-prefix", extracted_dir, "--set-godot-version", "4.4.1"],
                capture_output=True
            )

            # Launch modded game
            self.set_status(f"Running with {len(enabled_mods)} mod(s)...", "green")
            self.root.update()
            print(f"[DEBUG] Launching with {len(enabled_mods)} mods")

            if modded_executable.endswith(".exe") and os.name == "nt":
                subprocess.run(modded_executable, shell=True)
            else:
                subprocess.run([modded_executable])

            self.set_status("Game closed.", "gray")


    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    ModLoader().run()
