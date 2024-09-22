from conan import ConanFile
from conan.tools.scm import Git
from conan.tools.cmake import CMake
from conan.tools.files import get, copy
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout
import os


class ArmGccConan(ConanFile):
    # name = "hal"
    # version = "1.0"
    license = "GPL-3.0-only"
    homepage = ""
    url = ""
    author = "Ostanin <iahve1991@gmail.com>"
    description = "пакет HAL для arm"
    topics = ("conan", "hal")
    # options = {"source_url": ["ANY"]}
    # default_options = {"source_url": "None"}
    # settings = "os", "arch"
    package_type = "application"
    programs = {}
    sha = {}
    archive_name = {}
    # options = {"Device": ["STM32F0", "STM32F1", "STM32F3", "STM32F4", "STM32H7"]}
    exports_sources = "hal_template.cmake"#, "source_url.txt"
    # generators = "CMakeToolchain"

    # generators = "CMakeDeps"

    def requirements(self):
        print("HAL_REQUIREMENTS")
        # self.requires("cmsis_5/1.0")

    def system_requirements(self):
        print("HAL_PYTHON_REQUIREMENTS")

    # def requirements(self):
    #     self.requires("bs4/4.10.0")
    def validate(self):
        print("HAL_VALIDATION")
        # self.options.source_url = str(self.options.source_url)

    def package_id(self):
        print("HAL_PACKAGE_ID")


    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()
    def build(self):
        print("HAL_BUILD")


    def package(self):
        print("HAL_PACKAGE")
        print(self.source_folder +"/hal/Src")
        print(self.exports_sources)
        self.run(f"ls -la .")
        copy(self, "*.h", dst=self.package_folder + "/Include", src=self.source_folder +"/hal/Inc")
        copy(self, "*.c", dst=self.package_folder + "/HALSource", src=self.source_folder +"/hal/Src")
        # copy(self, "*.cmake", dst=self.package_folder+"/cmake", src=self.source_folder)
        with open(self.source_folder + "/hal_template.cmake", "r", encoding='utf-8') as file:
            hal_template_content = file.read()
            hal_template_content = hal_template_content.replace("@HAL@", self.name.upper())
            file.close()
        file_path = os.path.join(self.package_folder, "cmake", "hal_template.cmake")
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(self.package_folder + "/cmake/hal_template.cmake", "w+", encoding='utf-8') as file:
            file.write(hal_template_content)
            file.close()
        # copy(self, "source_url.txt", dst=self.package_folder, src=self.source_folder)

    def source(self):
        print("HAL_SOURCE")
        url = os.getenv("URL")
        print("URL: ", url)
        tag = os.getenv("TAG")
        print("TAG: ", tag)

        # with open(f"source_url.txt", "w") as file:
        #     file.write(url + "\n")
        #     file.write(tag + "\n")
        #     file.close()
        git = Git(self)

        git.clone(url, "hal")
        self.run(f"ls -la ./hal")
        self.run(f"cd ./hal && git checkout {tag}")
        # git.checkout("master")
    def package_info(self):
        print("HAL_PACKAGE_INFO")
        # cmake = CMake(self)
        # cmake.configure()
        # cmake.build()
        # self.cpp_info.includedirs = ["include"]
        # self.cpp_info.srcdirs = ["src"]
        # toolchain_path = os.path.join(self.package_folder, "hal.cmake")
        self.cpp_info.builddirs.append(os.path.join(self.package_folder, "cmake"))
        toolchain_path = os.path.join(self.package_folder, "cmake/hal.cmake")
        self.conf_info.append("tools.cmake.cmaketoolchain:user_toolchain", [toolchain_path])

        with open(self.package_folder + "/cmake/hal_template.cmake", "r", encoding='utf-8') as template_file:
            template_content = template_file.read()
            template_file.close()
        path =f"{self.package_folder}".replace("\\", "/")
        template_content = template_content.replace("@PATH@", path)


        with open(self.package_folder + "/cmake/hal.cmake", "w", encoding='utf-8') as toolchain_file:
            toolchain_file.write(template_content)
            toolchain_file.close()

    def generate(self):
        print("HAL_GENERATE")

