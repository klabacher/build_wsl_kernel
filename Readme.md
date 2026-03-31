# WSL2 Kernel Builder

A lightweight, interactive tool to build a custom WSL2 Linux kernel using a containerized environment. This project simplifies the process of configuring and compiling the kernel without cluttering the host system.

## Prerequisites

Docker installed and running on your system.
Bash shell environment to execute the builder script.

## Getting Started

Make the main builder script executable by running the following command in your terminal:

```bash
chmod +x wsl-builder.sh
```

Launch the interactive interface:

```bash
./wsl-builder.sh
```

## Available Options

1 Build default kernel
Compiles the latest WSL2 kernel using the standard Microsoft configuration. Use this if you just need a fresh build without modifications.

2 Run menuconfig
Opens the terminal-based kernel configuration tool. This allows you to enable or disable specific kernel features, modules, or drivers. Upon saving and exiting, your custom settings are stored in the out/custom.config file.

3 Build custom kernel
Compiles the kernel using the configuration generated in the previous step. You must run the menuconfig option at least once before using this option.

4 Clean workspace
Deletes the downloaded source code and any compiled artifacts from the workspace and out directories. This is useful for freeing up disk space or starting a build entirely from scratch.

5 Exit
Closes the interactive menu.

## Applying the Kernel

Once the build process completes successfully, the compiled kernel file is saved as bzImage inside the out directory. 

To use this new kernel in your WSL environment, copy the bzImage file to a location on your Windows file system, such as C:\Users\YourUsername\wsl-kernel\bzImage. 

Create or edit the .wslconfig file located in your Windows user profile folder. Add the following lines, adjusting the path to match where you saved the file:

```ini
[wsl2]
kernel=C:\\Users\\YourUsername\\wsl-kernel\\bzImage
```

Open PowerShell or Command Prompt and restart the WSL subsystem to apply the changes:

```powershell
wsl --shutdown
```