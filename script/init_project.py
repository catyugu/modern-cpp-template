import os
import sys
from pathlib import Path


def replace_in_file(filepath, replacements):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        new_content = content
        for old, new in replacements.items():
            new_content = new_content.replace(old, new)

        if content != new_content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
    except Exception as e:
        print(f"Skipping {filepath} due to error: {e}")


def should_skip(root):
    """跳过生成目录、版本控制与脚本自身，避免误改。"""
    return any(x in root for x in [".git", "build", "out", "script", ".cache"])


def main():
    print("=== Modern C++ Project Initializer ===")
    project_name = input("Enter Project Name (CamelCase, e.g., AwesomeApp): ").strip()
    namespace_name = input(
        "Enter Namespace/Prefix (lowercase, e.g., awesome): "
    ).strip()

    if not project_name or not namespace_name:
        print("Invalid input. Aborting.")
        sys.exit(1)

    # 替换规则：将模板占位符替换为用户输入
    # 顺序：先驼峰(MyProject)与全大写(MYPROJECT)，再小写前缀(myproject)，避免部分替换冲突
    replacements = {
        "MyProject": project_name,
        "MYPROJECT": project_name.upper(),
        "myproject": namespace_name,
    }

    # 获取项目根目录 (假设该脚本总是在 script/ 文件夹下)
    root_dir = Path(__file__).parent.parent.resolve()

    # 1. 自下而上重命名目录 (避免重命名父目录后找不到子目录)
    #    例如 myproject/ 与 myproject/include/myproject/
    for root, dirs, files in os.walk(root_dir, topdown=False):
        for dirname in dirs:
            if dirname == "myproject":
                old_path = os.path.join(root, dirname)
                new_path = os.path.join(root, namespace_name)
                os.rename(old_path, new_path)
                print(f"Renamed directory: {old_path} -> {new_path}")

    # 2. 自下而上重命名含模板占位符的文件
    #    例如 cmake/myprojectOptions.cmake -> cmake/<namespace>Options.cmake
    #    必须先于内容替换，否则 include(cmake/xxx) 路径与实际文件名对不上
    for root, dirs, files in os.walk(root_dir, topdown=False):
        if should_skip(root):
            continue
        for filename in files:
            new_name = filename
            if "MyProject" in filename:
                new_name = new_name.replace("MyProject", project_name)
            if "myproject" in filename:
                new_name = new_name.replace("myproject", namespace_name)
            if new_name != filename:
                old_path = os.path.join(root, filename)
                new_path = os.path.join(root, new_name)
                os.rename(old_path, new_path)
                print(f"Renamed file: {filename} -> {new_name}")

    # 3. 遍历处理文件内容
    for root, dirs, files in os.walk(root_dir):
        if should_skip(root):
            continue

        for filename in files:
            filepath = os.path.join(root, filename)
            replace_in_file(filepath, replacements)

    print(f"\n[OK] Project initialized successfully!")
    print(f"Project Name: {project_name}")
    print(f"Namespace/Prefix:   {namespace_name}")
    print("\nYou can now run:")
    print("  mkdir build && cd build")
    print("  cmake ..")
    print("  cmake --build .")


if __name__ == "__main__":
    main()
