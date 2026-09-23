package("vulkan-headers")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/KhronosGroup/Vulkan-Headers/")
    set_description("Vulkan Header files and API registry")
    set_license("Apache-2.0")
                    
    add_urls("https://github.com/KhronosGroup/Vulkan-Headers.git")
    add_urls("https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/$(version).tar.gz", {version = function (version)
        return version:startswith("v") and version or "vulkan-sdk-" .. version:gsub("%+", ".")
    end})

    -- when adding a new sdk version, please ensure vulkan-headers, vulkan-hpp, vulkan-loader, vulkan-tools, vulkan-validationlayers, vulkan-utility-libraries, spirv-headers, spirv-reflect, spirv-tools, glslang and volk packages are updated simultaneously
    add_versions("1.4.357+0", "e87dce08116151f6b6d7de6b6faf41498e87e6cf848ff16fa3bd5402190ad4a3")
    add_versions("1.4.350+1", "6d1bb65e49520344cc0a48af3dc02e993781efff14c7ebdcb8ae9fa23ddf7e83")
    add_versions("1.4.350+0", "70270d10bf2c1e074a06ee37a50b75d332993d1b80a1d9526eeed2da6d82ed22")
    add_versions("1.4.335+0", "269e95cc5138ea0a0d52fcb0ee19102add2560fedf5a43b1b5c17780c2775764")
    add_versions("1.4.309+0", "2bc1b4127950badc80212abf1edfa5c3b5032f3425edf37255863ba7592c1969")

    -- These macros must be defined at module-compile time (not at #include time), so we expose
    -- them as package configs. When modules=false users can simply #define before including.
    add_configs("modules", {description = "Build with C++20 modules support.", default = false, type = "boolean"})
    add_configs("cxx23", {description = "Use C++23 instead of C++20 (enables std::expected support in Vulkan-Hpp).", default = false, type = "boolean"})
    add_configs("assert_on_result", {description = "Set the expression(e.g. 'assert(x)').", default = nil, type = "string"})
    add_configs("enable_beta_extensions", {description = "Enable beta Vulkan extensions.", default = false, type = "boolean"})
    add_configs("enable_dynamic_loader_tool", {description = "Enable dynamic loader tool support.", default = true, type = "boolean"})
    add_configs("dispatch_loader_dynamic", {description = "Use dynamic dispatch loader.", default = false, type = "boolean"})
    add_configs("no_exceptions", {description = "Disable exceptions.", default = false, type = "boolean"})
    add_configs("no_constructors", {description = "Disable constructors for Vulkan-Hpp types.", default = false, type = "boolean"})

    on_load(function (package)
        if not package:config("modules") then
            package:add("deps", "cmake")
            if package:is_plat("mingw") and is_subhost("msys") then
                package:add("extsources", "pacman::vulkan-headers")
            elseif package:is_plat("linux") then
                package:add("extsources", "apt::libvulkan-dev")
            elseif package:is_plat("macosx") then
                package:add("extsources", "brew::vulkan-headers")
            end
        end
    end)

    on_install(function (package)
        if not package:config("modules") then
            import("package.tools.cmake").install(package, {
                "-DVULKAN_HEADERS_ENABLE_MODULE=OFF",
                "-DVULKAN_HEADERS_ENABLE_TESTS=OFF"
            })
        else
            local defines = {}
            if package:config("no_exceptions") then
                table.insert(defines, "VULKAN_HPP_NO_EXCEPTIONS")
            end
            if package:config("no_constructors") then
                table.insert(defines, "VULKAN_HPP_NO_CONSTRUCTORS")
            end
            if package:config("dispatch_loader_dynamic") then
                table.insert(defines, "VULKAN_HPP_DISPATCH_LOADER_DYNAMIC=1")
            end
            if package:config("enable_beta_extensions") then
                table.insert(defines, "VK_ENABLE_BETA_EXTENSIONS")
            end
            if package:config("enable_dynamic_loader_tool") then
                table.insert(defines, "VULKAN_HPP_ENABLE_DYNAMIC_LOADER_TOOL=1")
            else
                table.insert(defines, "VULKAN_HPP_ENABLE_DYNAMIC_LOADER_TOOL=0")
            end
            local assert_on_result = package:config("assert_on_result")
            if assert_on_result then
                table.insert(defines, "VULKAN_HPP_ASSERT_ON_RESULT(x)=" .. assert_on_result)
            end
            local std_lang = package:config("cxx23") and "c++23" or "c++20"
            local def_parts = {}
            for _, d in ipairs(defines) do
                table.insert(def_parts, format('"%s"', d))
            end
            io.writefile("xmake.lua", format([[
                target("vulkan-headers")
                    set_kind("moduleonly")
                    set_languages("%s")
                    add_headerfiles("include/(**.h)")
                    add_headerfiles("include/(**.hpp)")
                    add_includedirs("include")
                    add_files("include/**.cppm", {public = true})
                    add_defines(%s)
            ]], std_lang, table.concat(def_parts, ", ")))
            local configs = {}
            import("package.tools.xmake").install(package, configs)
        end
    end)

    on_test(function (package)
        assert(package:check_csnippets({test = [[
            void test() {
                int version = VK_HEADER_VERSION;
            }
        ]]}, {includes = "vulkan/vulkan.h"}))
    end)