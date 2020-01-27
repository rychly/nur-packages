{ stdenv, mkdocs
, pythonPackages
, plugins
}:

(mkdocs
.override {
  python = pythonPackages.python.withPackages plugins;
})
.overridePythonAttrs (oldAttrs: {
  pname = oldAttrs.pname + "-with-plugins";
  propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ (plugins pythonPackages);
  doCheck = false;	# skip for failing test_get_themes in mkdocs.tests.utils.utils_tests.UtilsTests after adding new mkdocs themes by plugins
} )
