package("volk")
    set_homepage("https://github.com/zeux/volk")
    set_description("volk is a meta-loader for Vulkan")
    set_license("MIT")

    add_urls("https://github.com/zeux/volk/archive/refs/tags/$(version).tar.gz", {alias = "archive", version = function (version)
        return "vulkan-sdk-" .. version:gsub("%+", ".")
    end})
    add_urls("https://github.com/zeux/volk.git", {alias = "git"})

    -- when adding a new sdk version, please ensure vulkan-headers, vulkan-hpp, vulkan-loader, vulkan-tools, vulkan-validationlayers, vulkan-utility-libraries, spirv-headers, spirv-reflect, spirv-tools, glslang and volk packages are updated simultaneously
    add_versions("archive:1.4.357+0", "6400c7b23e24d17e4f04bac49b55b06c4e87677d33398e90344743ec73560ca6")
    add_versions("archive:1.4.350+1", "078a9411298e4e0f60f5f5398c890783427c25a414619294ca8e69587bbd5eae")
    add_versions("archive:1.4.350+0", "a04f26f76e9a4f9acf936bd2c159f5c4c8348f8ebaf118ff72ba6a9637ad3e80")
    add_versions("archive:1.4.335+0", "ca2beb1ab9bf272895bc0152ef29b437d178d837bae4a76d0022b7bbafb3c483")
    add_versions("archive:1.4.309+0", "1724924d8e3dccf0c508887edb79d56d9dd11b0738eab5a44e2fa95b8a9ebe1c")

    add_versions("git:1.4.357+0", "vulkan-sdk-1.4.357.0")
    add_versions("git:1.4.350+1", "vulkan-sdk-1.4.350.1")
    add_versions("git:1.4.350+0", "vulkan-sdk-1.4.350.0")
    add_versions("git:1.4.335+0", "vulkan-sdk-1.4.335.0")
    add_versions("git:1.4.309+0", "vulkan-sdk-1.4.309.0")

    add_configs("header_only", {description = "Header only.", default = false, type = "boolean"})
    add_configs("shared", {description = "Build shared library.", default = false, type = "boolean", readonly = true})

    if is_plat("linux") then
        add_syslinks("dl")
    end

    on_load(function (package)
        if package:config("header_only") then
            package:set("kind", "library", {headeronly = true})
        end
        if not package.is_built or package:is_built() then
            package:add("deps", "cmake")
        end
        local sdkver = package:version():split("%+")[1]
        package:add("deps", "vulkan-headers " .. sdkver)
    end)

    on_install("windows", "linux", "macosx", "mingw", "iphoneos", "android", function (package)
        if package:config("header_only") then
            io.replace("CMakeLists.txt", "if(NOT VOLK_HEADERS_ONLY OR VOLK_INSTALL)", "if(NOT VOLK_HEADERS_ONLY)", {plain = true})
            io.replace("CMakeLists.txt", "install(TARGETS volk volk_headers", "install(TARGETS volk_headers", {plain = true})
        end

        local vulkanheaders = package:dep("vulkan-headers")
        local configs = {}
        table.insert(configs, "-DVOLK_PULL_IN_VULKAN=ON")
        table.insert(configs, "-DVOLK_INSTALL=ON")
        table.insert(configs, "-DVULKAN_HEADERS_INSTALL_DIR=" .. vulkanheaders:installdir())
        table.insert(configs, "-DVOLK_HEADERS_ONLY=" .. (package:config("header_only") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        local defines
        if package:config("header_only") then
            defines = "VOLK_IMPLEMENTATION"
        end

        assert(package:check_csnippets({test = [[
            #include <volk.h>
            void test() {
                volkInitialize();
            }
        ]]}, {configs = {defines = defines}}))
    end)
