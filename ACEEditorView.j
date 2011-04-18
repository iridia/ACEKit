//	ACEEditorView.j
//	ACEKit, Evadne Wu at Iridia, 2011
	
@import <AppKit/CPWebView.j>

@implementation ACEEditorView : CPWebView {
	
	id editor @accessors;
	id actualWindow;	// the window passed from the iframe
	id actualDocument;	// The DOM element from the iframe’s window
	
	CPString themeName @accessors; // actually setThemeName would work too
	
}

- (id) editorNamespace {
	
	return [self objectByEvaluatingJavaScriptFromString:@"ACENamespace()"];
	
}

- (id) initWithFrame:(CGRect)aFrame {
	
	self = [super initWithFrame:aFrame];
	if (!self) return nil;
	
	[self akInitialize];
	
	return self;
	
}

- (id) initWithCoder:(CPCoder)aCoder {
	
	self = [super initWithCoder:aCoder];
	if (!self) return nil;
	
	[self akInitialize];
	
	return self;
	
}

- (void) akInitialize {
	
	[self setDrawsBackground:NO];
	[self setBackgroundColor:[CPColor whiteColor]];
	[self setScrollMode:CPWebViewScrollNative];
	[self setFrameLoadDelegate:self];
	[self setMainFrameURL:[[CPBundle bundleForClass:[self class]] pathForResource:"ace.html"]];
	
	[self setThemeName:@"theme-dawn"];
	
}

- (void) webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame {
	
	[self setEditor:[self objectByEvaluatingJavaScriptFromString:@"ACCEditorViewInitialize()"]];
	[self setThemeName:[self themeName]];
	
}





- (BOOL) acceptsFirstResponder {
	
	return (!![self editor]); // && [self isEditable] && [self isEnabled]);
	
}

- (BOOL) becomeFirstResponder {
	
	var answer = [super becomeFirstResponder];	
	return answer;
	
}

- (BOOL) resignFirstResponder {
	
	var answer = [super resignFirstResponder];
	
	if (answer) {
		
		actualWindow.blur();
		window.focus(); //	So, the key events get through
		
	}
	
	return answer;
	
}





- (void) setEditor:(id)newEditor {

	if (editor === newEditor)
	return;

	if (![self DOMWindow])
	return;

	editor = newEditor;
	_iframe.allowTransparency = true;

	actualWindow = [self DOMWindow];
	actualDocument = actualWindow.document;
	
	var bind = function (target, eventName, eventHandler) {
		
		actualHandler = function (event) {
			
			if (eventHandler)
			eventHandler(event || window.event);
			
		}
		
		if (target.addEventListener) {
		
			target.addEventListener(eventName, actualHandler, true);
		
		} else if (target.attachEvent) {	 // IE WTF
			
			target.attachEvent(eventName, actualHandler);
			
		}
		
	};
	
	bind(actualDocument, "blur", function (event) {

		actualWindow.blur();
		window.focus(); //	So, the key events get through
		[self resignFirstResponder];
	
	});
	
	bind(actualWindow, "blur", function (event) {
		
		window.focus();
		
	});
	
	bind(actualDocument, "focus", function (event) {
	
		if (![[self window] isKeyWindow])
		[[self window] makeKeyAndOrderFront:self];
	
		actualWindow.focus();  // So, the key events get through
		[self becomeFirstResponder];

	});
	
	bind(actualWindow, "focus", function (event) {
		
		if (![[self window] isKeyWindow])
		[[self window] makeKeyAndOrderFront:self];
		
		[self becomeFirstResponder];
		actualWindow.focus();
		
	});

	bind(actualDocument, "mousedown", function (event) {
		
		actualWindow.focus();
	
	});

}

@end




//	Note, there might be an JSON / Objective-J abstraction leak here
//	If you use literals they are taken as the real thing
//	For example in { a: "foobar" } even though var a = "b" it evaluates to { "a": "foobar" }
//	So don’t change the values of these defines
	
var kACEEditorViewThemeTitle = @"kACEEditorViewThemeTitle";
var kACEEditorViewThemeFileLocation = @"kACEEditorViewThemeFileLocation";
var kACEEditorViewThemeInternalName = @"kACEEditorViewThemeInternalName";

var kACEEditorViewThemeFileLocationPrefix = @"ace/build/src/";

var kACEEditorViewResource = function (aName) { return [[CPBundle bundleForClass:[ACEEditorView class]] pathForResource:aName]; };
var kACEEditorViewThemeResource = function (aName) { return [[CPBundle bundleForClass:[ACEEditorView class]] pathForResource:(kACEEditorViewThemeFileLocationPrefix + "/" + aName + ".js")]; };

@implementation ACEEditorView (ThemingSupport) {

+ (CPDictionary) defaultThemes {
	
	var transformedObject = {};
	var enqueue = function (shortName, name, internalName) {
		
		transformedObject[shortName] = {
		
			kACEEditorViewThemeTitle: name,
			kACEEditorViewThemeFileLocation: kACEEditorViewThemeResource(shortName),
			kACEEditorViewThemeInternalName: internalName			
		
		};
	
	};
	
	enqueue("theme-clouds", "Clouds", "ace/theme/clouds");
	enqueue("theme-clouds_midnight", "Clouds (Midnight)", "ace/theme/clouds_midnight");
	enqueue("theme-cobalt", "Cobalt", "ace/theme/cobalt");
	enqueue("theme-dawn", "Dawn", "ace/theme/dawn");
	enqueue("theme-eclipse", "Eclipse", "ace/theme/eclipse");
	enqueue("theme-idle_fingers", "Idle Fingers", "ace/theme/idle_fingers");
	enqueue("theme-kr_theme", "KR Theme", "ace/theme/kr_theme");
	enqueue("theme-merbivore", "Merbivore", "ace/theme/merbivore");
	enqueue("theme-merbivore_soft", "Merbivore (Soft)", "ace/theme/merbivore_soft");
	enqueue("theme-mono_industrial", "Mono (Industrial)", "ace/theme/mono_industrial");
	enqueue("theme-pastel_on_dark", "Pastel On Dark", "ace/theme/pastel_on_dark");
	enqueue("theme-twilight", "Twilight", "ace/theme/twilight");
	enqueue("theme-vibrant_ink", "Vibrant Ink", "ace/theme/vibrant_ink");
	
	return [CPDictionary dictionaryWithJSObject:transformedObject recursively:YES]; // This is super important
	
}

- (void) setThemeName:(CPString)newName {
		
	themeName = newName;
	
	if (![self editorNamespace])
	return; // save this for later
	
	//	First inject something
	var themeData = [[[self class] defaultThemes] objectForKey:themeName];
	
	if (!themeData)
	[CPException raise:CPInternalInconsistencyException reason:[CPString stringWithFormat:@"Can’t find data for theme named %@ not found at all.", themeName]];
	
	var internalThemeName = [themeData objectForKey:kACEEditorViewThemeInternalName];
	var themeLocation = [themeData objectForKey:kACEEditorViewThemeFileLocation];
	
	ACELoadScript(themeLocation, function () {
		
		if ([self editor] && [self editor].setTheme) {

			[self editor].setTheme(internalThemeName);
		
		} else {
		
			CPLog(@"did not really set the theme successfully");
		
		}
		
	}, [self DOMWindow].document);
	
}

@end





var ACELoadScript = function (scriptURI, callbackBlock, aDocument) {
	
	if (!aDocument)
	aDocument = document;

	var DOMScriptElement = aDocument.createElement("script");
	DOMScriptElement.src = scriptURI;
	DOMScriptElement.type = "text/javascript";
		
	if (DOMScriptElement.readyState) {  //IE

		DOMScriptElement.onreadystatechange = function () {
			
			if (script.readyState == "loaded" || script.readyState == "complete") {
			
				script.onreadystatechange = null;
				callbackBlock();
			
			}
	
		};
	
	} else {

		DOMScriptElement.onload = function () {

			callbackBlock();
	
		};
	
	}
	
	aDocument.getElementsByTagName("head")[0].appendChild(DOMScriptElement);

}
