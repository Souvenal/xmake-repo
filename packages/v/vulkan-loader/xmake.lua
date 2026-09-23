package("vulkan-loader")
    set_homepage("https://github.com/KhronosGroup/Vulkan-Loader")
    set_description("This project provides the Khronos official Vulkan ICD desktop loader for Windows, Linux, and MacOS.")
    set_license("Apache-2.0")

    add_urls("https://github.com/KhronosGroup/Vulkan-Loader/archive/$(version).tar.gz", {version = function (version)
        return "vulkan-sdk-" .. version:gsub("%+", ".")
    end})

    -- when adding a new sdk version, please ensure vulkan-headers, vulkan-hpp, vulkan-loader, vulkan-tools, vulkan-validationlayers, vulkan-utility-libraries, spirv-headers, spirv-reflect, spirv-tools, glslang and volk packages are updated simultaneously
    add_versions("1.4.357+0", "54f2537df22313768da0317dda2abdaaab7711b4081c48c869a79db343d0ae70")
    add_versions("1.4.350+1", "602984a71000981e25e4feb419e6cdd70b18ffe2b8004f60f591706027bca468")
    add_versions("1.4.350+0", "91f88fc43abb36821a568c7fbb3f815e9baf946d5fe187928df279708d45e509")
    add_versions("1.4.335+0", "e1d7f598d42fa87b38fd7e984968c660e406168db64df8e8e23c5be3a66e9bd8")
    add_versions("1.4.309+0", "ddfeca84a868899fbb2c7f28b7c8fd1006e34b2b13ce653a63bddfb65cbc8d13")

    add_configs("shared", {description = "Build shared library.", default = true, type = "boolean", readonly = true})

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::vulkan-loader")
    elseif is_plat("linux") then
        add_extsources("apt::libvulkan-dev", "pacman::vulkan-icd-loader")
        add_deps("wayland", "libxrandr", "libxrender", "libxcb", "libxkbcommon")
    elseif is_plat("macosx") then
        add_extsources("brew::vulkan-loader")
    end

    -- xmake doesn't pass environment variables to make (such as LD_LIBRARY_PATH) but passes them to Ninja
    if is_plat("linux") then
        set_policy("package.cmake_generator.ninja", true)
    end

    on_load("windows", "linux", "macosx", function (package)
        local sdkver = package:version():split("%+")[1]
        package:add("deps", "vulkan-headers " .. sdkver)
        if not package.is_built or package:is_built() then
            package:add("deps", "cmake", "ninja")
            if package:is_plat("linux") then
                package:add("deps", "ninja")
            end
        end
        if package:is_plat("macosx") then
            package:add("links", "vulkan")
        end
    end)

    on_fetch("macosx", function (package, opt)
        if opt.system then
            import("lib.detect.find_path")
            local libdir = find_path("libvulkan.dylib", "~/VulkanSDK/*/macOS/lib")
            local includedir = find_path("vulkan/vulkan.h", "~/VulkanSDK/*/macOS/include")
            if libdir and includedir then
                return {linkdirs = libdir, links = "vulkan", includedirs = includedir}
            end
        end
    end)

    on_install("windows|x86", "windows|x64", "linux", "macosx", function (package)
        import("package.tools.cmake")
        local envs = cmake.buildenvs(package)
        local opt = {envs = envs}
        if package:is_plat("linux") then
            opt.packagedeps = {"wayland", "libxrandr", "libxrender", "libxcb", "libxkbcommon"}
            local linkdirs = {}
            for _, lib in ipairs({"wayland", "libxrandr", "libxcb", "libxkbcommon"}) do
                local fetchinfo = package:dep(lib):fetch()
                if fetchinfo then
                    for _, dir in ipairs(fetchinfo.linkdirs) do
                        table.insert(linkdirs, dir)
                    end
                end
            end
            envs.LD_LIBRARY_PATH = (envs.LD_LIBRARY_PATH or "") .. path.envsep() .. path.joinenv(table.unique(linkdirs))
        end
        local configs = {"-DBUILD_TESTS=OFF"}
        local vulkan_headers = package:dep("vulkan-headers")
        table.insert(configs, "-DVULKAN_HEADERS_INSTALL_DIR=" .. vulkan_headers:installdir())
        cmake.install(package, configs, opt)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("vkGetDeviceProcAddr", {includes = "vulkan/vulkan_core.h"}))
    end)