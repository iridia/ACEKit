//	ACEEditorView.j
//	ACEKit, Evadne Wu at Iridia, 2011
	
@import <AppKit/CPWebView.j>

@implementation ACEEditorView : CPWebView

- (id) editorNamespace {
	
	return [self objectByEvaluatingJavaScriptFromString:@"ACCNamespace()"];
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
	
	var results = [self objectByEvaluatingJavaScriptFromString:@"ACCEditorViewInitialize()"];
	
	if (results !== true)
	CPLog(@"Error: Initialization failed");
	
}

@end
