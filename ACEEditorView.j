//	ACEEditorView.j
//	ACEKit, Evadne Wu at Iridia, 2011
	
@import <AppKit/CPWebView.j>

@implementation ACEEditorView : CPWebView {
	
	id editor @accessors;
	id actualWindow;	// the window passed from the iframe
	id actualDocument;	// The DOM element from the iframe’s window
	
	CPString themeName @accessors; // actually setThemeName would work too
	CPString modeName @accessors; // actually setModeName would work too
	CPString contentText @accessors;
	
}

- (id) editorNamespace {
	
	return [self objectByEvaluatingJavaScriptFromString:@"ACENamespace()"];
	
}

- (id) editorSession {
	
	return [self editor] && [self editor].getSession() || nil;
	
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
	[self setContentText:contentText]; // don’t go thru the getter
	
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
		
		editor.onBlur();
		
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
	
	[self setContentText:contentText];
	
	if (themeName) [self setThemeName:themeName];
	if (modeName) [self setModeName:modeName];

}

- (CPString) contentText {
	
	if (![self editor])
	return contentText;
	
	var retrievedValue = [self editor].getSession().getValue();
	[self setContentText:retrievedValue];
	
	return contentText;
	
}

- (void) setContentText:(CPString)newContentText {
	
	var propagateKVO = (![contentText isEqual:newContentText]);
	
	if (propagateKVO) [self willChangeValueForKey:@"themeName"];
	contentText = newContentText;
	if (propagateKVO) [self didChangeValueForKey:@"themeName"];
	
	if ([self editorSession]) {
		
		[self editorSession].setValue((contentText || @""));
	
	}
	
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

@implementation ACEEditorView (ThemingSupport)

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
	
	var propagateKVO = (![themeName isEqual:newName]);
	
	if (propagateKVO) [self willChangeValueForKey:@"themeName"];
	themeName = newName;
	if (propagateKVO) [self didChangeValueForKey:@"themeName"];
	
	if (![self editorNamespace])
	return; // So in the future this can get called again and KVO will NOT fire, but the change will get into the editor nevertheless

	var themeData = [[[self class] defaultThemes] objectForKey:themeName];
	
	if (!themeData) {
		
		[CPException raise:CPInternalInconsistencyException reason:[CPString stringWithFormat:@"Can’t find data for theme named %@.", themeName]];
		
	}	
	
	var internalThemeName = [themeData objectForKey:kACEEditorViewThemeInternalName];
	var themeLocation = [themeData objectForKey:kACEEditorViewThemeFileLocation];
	
	ACELoadScript(themeLocation, function () {
		
		if ([self editor] && [self editor].setTheme) {

			[self editor].setTheme(internalThemeName);
		
		} else {
		
			CPLog(@"Warning: did not set the theme successfully");
		
		}
		
	}, [self DOMWindow].document);
	
}

@end





var kACEEditorViewModeTitle = @"kACEEditorViewModeTitle";
var kACEEditorViewModeFileLocation = @"kACEEditorViewModeFileLocation";
var kACEEditorViewModeInternalName = @"kACEEditorViewModeInternalName";

var kACEEditorViewModeFileLocationPrefix = @"ace/build/src/";
var kACEEditorViewModeResource = function (aName) { return [[CPBundle bundleForClass:[ACEEditorView class]] pathForResource:(kACEEditorViewThemeFileLocationPrefix + "/" + aName + ".js")]; };

@implementation ACEEditorView (SyntaxHighlightingSupport)

+ (CPDictionary) defaultModes {

	var transformedObject = {};
	var enqueue = function (shortName, name, internalName) {

		transformedObject[shortName] = {

			kACEEditorViewModeTitle: name,
			kACEEditorViewModeFileLocation: kACEEditorViewModeResource(shortName),
			kACEEditorViewModeInternalName: internalName

		};

	};
	
	enqueue("mode-c_cpp", "C++", "ace/mode/c_cpp");
	enqueue("mode-coffee", "CoffeeScript", "ace/mode/coffee");
	enqueue("mode-csharp", "C#", "ace/mode/csharp");
	enqueue("mode-css", "CSS", "ace/mode/css");
	enqueue("mode-html", "HTML", "ace/mode/html");
	enqueue("mode-java", "Java", "ace/mode/java");
	enqueue("mode-javascript", "JavaScript", "ace/mode/javascript");
	enqueue("mode-perl", "Perl", "ace/mode/perl");
	enqueue("mode-php", "PHP", "ace/mode/php");
	enqueue("mode-python", "Python", "ace/mode/python");
	enqueue("mode-ruby", "Ruby", "ace/mode/ruby");
	enqueue("mode-svg", "SVG", "ace/mode/svg");
	enqueue("mode-xml", "XML", "ace/mode/xml");

	return [CPDictionary dictionaryWithJSObject:transformedObject recursively:YES]; // This is super important

}

- (void) setModeName:(CPString)newName {

	var propagateKVO = (![themeName isEqual:newName]);

	if (propagateKVO) [self willChangeValueForKey:@"modeName"];
	modeName = newName;
	if (propagateKVO) [self didChangeValueForKey:@"modeName"];

	if (![self editorNamespace])
	return; // So in the future this can get called again and KVO will NOT fire, but the change will get into the editor nevertheless

	var modeData = [[[self class] defaultModes] objectForKey:modeName];

	if (!modeData) {

		[CPException raise:CPInternalInconsistencyException reason:[CPString stringWithFormat:@"Can’t find data for mode named %@.", themeName]];

	}	

	var internalModeName = [modeData objectForKey:kACEEditorViewModeInternalName];
	var modeLocation = [modeData objectForKey:kACEEditorViewModeFileLocation];

	ACELoadScript(modeLocation, function () {
		
		//	Alright, I am not bothering, since in ACE speak, one must first create a Mode object, but we actually loaded the script that made the class *within the editor*
		//	In that case it is better to just throw a helper function there, and make it load things on its own behalf!
		
		[self DOMWindow].ACEEditorSetModeName(internalModeName);

	}, [self DOMWindow].document);

}

@end





@implementation ACEEditorView (UndoAndRedo)

//	I am not sure if this is adequare, because actually a lot of state is delegated to ACE itself; we are not exposing an undo manager or anything like that
//	Actually this part does not work with Objective-J / Cappuccino”s global undo / redo at all

- (void) undo:(id)sender {
	
	if ([self editorObject])
	[self editorObject].undo();
	
}

- (void) redo:(id)sender {
	
	if ([self editorObject])
	[self editorObject].redo();
	
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
