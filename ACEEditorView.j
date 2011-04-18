//	ACEEditorView.j
//	ACEKit, Evadne Wu at Iridia, 2011
	
@import <AppKit/CPWebView.j>

@implementation ACEEditorView : CPWebView {
	
	id editor @accessors;
	id actualWindow;	// the window passed from the iframe
	id actualDocument;	// The DOM element from the iframe’s window
	
}

- (id) editorNamespace {
	
	return [self objectByEvaluatingJavaScriptFromString:@"ACENamespace()"];
	//	return ([self DOMWindow] && [self DOMWindow].ace) || nil;
	
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
	
}

- (void) webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame {
	
	[self setEditor:[self objectByEvaluatingJavaScriptFromString:@"ACCEditorViewInitialize()"]];
	
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
