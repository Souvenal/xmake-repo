package("ryml")
    set_kind("library")
    set_homepage("https://github.com/biojppm/rapidyaml")
    set_description("Rapid YAML parser and emitter for C++")
    set_license("MIT")

    add_urls("https://github.com/biojppm/rapidyaml/archive/refs/tags/$(version).tar.gz",
             "https://github.com/biojppm/rapidyaml.git")
    add_versions("v0.16.0", "ad4337d468c5f5d8624651bdc2900f7fe601c83fc3cff669dc972bf8634af4e9")

    add_configs("tab_tokens", {
        description = "Enable parsing tabs after ':' and '-'.",
        default = false,
        type = "boolean"
    })
    add_configs("default_callbacks", {
        description = "Enable ryml's default allocate, free and error callbacks.",
        default = true,
        type = "boolean"
    })
    add_configs("callback_exceptions", {
        description = "Throw exceptions from ryml's default error callback.",
        default = false,
        type = "boolean"
    })
    add_configs("legacy_operators", {
        description = "Keep legacy operators such as '=' and '<<' without deprecation warnings.",
        default = false,
        type = "boolean"
    })
    add_configs("use_assert", {
        description = "Enable ryml assertions regardless of build type.",
        default = false,
        type = "boolean"
    })

    add_deps("cmake")

    on_check(function (package)
        assert(not package:config("callback_exceptions") or package:config("default_callbacks"),
               "package(ryml): callback_exceptions requires default_callbacks")
    end)

    on_install(function (package)
        local configs = {
            "-DRYML_BUILD_TESTS=OFF",
            "-DRYML_BUILD_BENCHMARKS=OFF",
            "-DRYML_BUILD_TOOLS=OFF",
            "-DRYML_BUILD_API=OFF",
            "-DRYML_DEFAULT_CALLBACKS=" .. (package:config("default_callbacks") and "ON" or "OFF"),
            "-DRYML_DEFAULT_CALLBACK_USES_EXCEPTIONS=" .. (package:config("callback_exceptions") and "ON" or "OFF"),
            "-DRYML_WITH_LEGACY_OPERATORS=" .. (package:config("legacy_operators") and "ON" or "OFF"),
            "-DRYML_USE_ASSERT=" .. (package:config("use_assert") and "ON" or "OFF"),
            "-DRYML_WITH_TAB_TOKENS=" .. (package:config("tab_tokens") and "ON" or "OFF"),
            "-DRYML_INSTALL=ON"
        }
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <cassert>
            #include <string>
            #include <ryml.hpp>

            void test() {
                ryml::Tree tree = ryml::parse_in_arena("name: ryml\nversion: 0.16.0\n");
                assert(tree["name"].val() == "ryml");
                assert(tree["version"].val() == "0.16.0");
            }
        ]]}, {configs = {languages = "c++11"}}))
    end)
