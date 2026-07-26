package("imgui-club")
    set_homepage("https://github.com/ocornut/imgui_club")
    set_description("Officially maintained small extensions for Dear ImGui")
    set_license("MIT")

    add_urls("https://github.com/ocornut/imgui_club.git")

    add_versions("2026.07.22", "a436e793fe44a2c8e827bfcbf138fcbe11940476")

    add_deps("imgui master")

    on_install("windows", "linux", "macosx", "mingw", "android", "iphoneos", function (package)
        local imgui = package:dep("imgui")
        local configs = imgui:requireinfo().configs
        if configs then
            configs = string.serialize(configs, {strip = true, indent = false})
        end
        io.writefile("xmake.lua", format([[
            add_rules("mode.debug", "mode.release")
            set_languages("c++11")
            add_requires("imgui %s", {configs = %s})
            target("imgui-club")
                set_kind("$(kind)")
                add_files("imgui_multicontext_compositor/imgui_multicontext_compositor.cpp")
                add_headerfiles(
                    "imgui_memory_editor/imgui_memory_editor.h",
                    "imgui_multicontext_compositor/imgui_multicontext_compositor.h",
                    "imgui_threaded_rendering/imgui_threaded_rendering.h")
                add_packages("imgui")
                if is_plat("windows") and is_kind("shared") then
                    add_rules("utils.symbols.export_all", {export_classes = true})
                end
        ]], imgui:version_str(), configs))
        import("package.tools.xmake").install(package)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            void test() {
                MemoryEditor memory_editor;
                ImGuiMultiContextCompositor compositor;
                ImDrawDataSnapshot snapshot;
            }
        ]]}, {configs = {languages = "c++11"}, includes = {
            "imgui.h",
            "imgui_memory_editor.h",
            "imgui_multicontext_compositor.h",
            "imgui_threaded_rendering.h"
        }}))
    end)
