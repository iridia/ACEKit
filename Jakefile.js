//	IRInterfaceKit Jakefile
	
	var PRODUCT_NAME = "ACEKit";
	var PROJECT_IDENTIFIER = "com.iridia.aceKit";
	
	
	
	
	
	var ENV = require("system").env;
	var BUILD_CONFIGURATION = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug";
	var FILE = require("file"), JAKE = require("jake"), OS = require("os");
	var app = require("cappuccino/jake").app, task = JAKE.task, configuration = BUILD_CONFIGURATION;
	var FileList = JAKE.FileList;
	
	var printResults = function (configuration) { print(configuration + " app built at path: " + FILE.join("Build", configuration, PRODUCT_NAME)); };
	var makeDirectoriesFor = function (aConfiguration) { FILE.mkdirs(FILE.join("Build", aConfiguration, PRODUCT_NAME));	};
	
	var configureEnvironmentFor = function (intendedEnvironment) {
	
		print("environment -> " + intendedEnvironment);
		ENV["CONFIGURATION"] = intendedEnvironment;
			
	}
	
	require("objective-j/jake").framework(PRODUCT_NAME, function (task) {
		
		task.setBuildIntermediatesPath(FILE.join("Build", (PRODUCT_NAME + ".build"), configuration));
		task.setBuildPath(FILE.join("Build", configuration));
		task.setProductName(PRODUCT_NAME);
		task.setIdentifier(PROJECT_IDENTIFIER);
		task.setVersion("0.0.1");
		task.setAuthor("Iridia");
		task.setEmail("hi@iridia.tw");
		task.setSummary("ACE Integration Kit for Cappuccino");
		task.setSources((new FileList("**/*.j")).exclude(FILE.join("Build", "**")));
		task.setFlattensSources(true);
		task.setResources(new FileList("Resources/**"));
		task.setInfoPlistPath("Info.plist");
		task.setNib2CibFlags("-R Resources/");
		task.setCompilerFlags((configuration === "Debug") ? "-DDEBUG -g" : "-O");
	
	});
	
	
	task("default", [PRODUCT_NAME], function () { printResults(configuration); });
	task("build", ["default"]);
	task("debug", function () { configureEnvironmentFor("Debug"); JAKE.subjake(["."], "build", ENV); });
	task("release", function () { configureEnvironmentFor("Release"); JAKE.subjake(["."], "build", ENV); });

	task("deploy", ["release"], function () {
		
		makeDirectoriesFor("Deployment");
		OS.system(["press", "-f", FILE.join("Build", "Release", PRODUCT_NAME), FILE.join("Build", "Deployment", PRODUCT_NAME)]);
		printResults("Deployment")
	
	});

	task("desktop", ["release"], function () {

		makeDirectoriesFor("Desktop");
		require("cappuccino/nativehost").buildNativeHost(FILE.join("Build", "Release", PRODUCT_NAME), FILE.join("Build", "Desktop", PRODUCT_NAME, PRODUCT_NAME + ".app"));
		printResults("Desktop")

	});
	
	task("run", ["debug"], function () { OS.system(["open", FILE.join("Build", "Debug", PRODUCT_NAME, "index.html")]); });
	task("run-release", ["release"], function () { OS.system(["open", FILE.join("Build", "Release", PRODUCT_NAME, "index.html")]);  });
	task("run-desktop", ["desktop"], function() { OS.system([FILE.join("Build", "Desktop", PRODUCT_NAME, PRODUCT_NAME + ".app", "Contents", "MacOS", "NativeHost"), "-i"]); });
