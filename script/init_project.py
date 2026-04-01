import os
import sys
from pathlib import Path

def replace_in_file(filepath, replacements):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content
        for old, new in replacements.items():
            new_content = new_content.replace(old, new)
            
        if content != new_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
    except Exception as e:
        print(f"Skipping {filepath} due to error: {e}")

def main():
    print("=== Modern C++ Project Initializer ===")
    project_name = input("Enter Project Name (CamelCase, e.g., AwesomeApp): ").strip()
    namespace_name = input("Enter Namespace/Prefix (lowercase, e.g., awesome): ").strip()

    if not project_name or not namespace_name:
        print("Invalid input. Aborting.")
        sys.exit(1)

    # 替换规则：将模板占位符替换为用户输入
    replacements = {
        "MyProject": project_name,
        "myproject": namespace_name
    }

    # 获取项目根目录 (假设该脚本总是在 script/ 文件夹下)
    root_dir = Path(__file__).parent.parent.resolve()

    # 1. 自下而上重命名目录 (避免重命名父目录后找不到子目录)
    for root, dirs, files in os.walk(root_dir, topdown=False):
        for dirname in dirs:
            if dirname == "myproject":
                old_path = os.path.join(root, dirname)
                new_path = os.path.join(root, namespace_name)
                os.rename(old_path, new_path)
                print(f"Renamed directory: {old_path} -> {new_path}")

    # 2. 遍历处理文件内容
    for root, dirs, files in os.walk(root_dir):
        # 忽略 git, build 生成目录和 script 目录自身
        if any(x in root for x in ['.git', 'build', 'out', 'script']):
            continue
        
        for filename in files:
            if filename.endswith(('.cpp', '.hpp', '.h', '.cmake', '.txt')):
                filepath = os.path.join(root, filename)
                replace_in_file(filepath, replacements)
    
    print(f"\n✅ Project initialized successfully!")
    print(f"Project Name: {project_name}")
    print(f"Namespace/Prefix:   {namespace_name}")
    print("\nYou can now run:")
    print("  mkdir build && cd build")
    print("  cmake ..")
    print("  cmake --build .")

if __name__ == "__main__":
    main()
