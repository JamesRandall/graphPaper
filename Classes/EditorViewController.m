    //
//  EditorViewController.m
//  graphPaper
//
//  Created by James Randall on 11/10/2010.
//  Copyright 2010 Accidental Fish. All rights reserved.
//

#import "EditorViewController.h"
#import "PropertiesViewController.h"
#import "GraphPaper.h"
#import "GraphPaperView.h"
#import "GrabHandle.h"
#import "Color.h"
#import "Polygon.h"
#import "Ellipse.h"
#import "ColorPicker.h"
#import "ExportViewController.h"

@interface EditorViewController (private)
- (void)setBarButtonStates;
- (NSArray*)defaultToolbarItems;
- (NSArray*)polygonEditToolbarItems;
- (void)createGrabHandles;
@end

@implementation EditorViewController (private)

- (void)setBarButtonStates
{
	switch (self.editMode)
	{
		case emLayout:
			self.editmodeControl.selectedSegmentIndex = 0;
			break;
			
		case emPolygon:
			self.editmodeControl.selectedSegmentIndex = 1;
			break;
			
		case emEllipse:
			self.editmodeControl.selectedSegmentIndex = 2;
			break;
	}
	
	self.properties.enabled = YES;
	self.trash.enabled = self.selectedShape != nil;
	self.export.enabled = self.graphPaper.shapes.count > 0;
}

- (NSArray*)defaultToolbarItems
{
	return [NSArray arrayWithObjects:self.pages,
			self.export,
			self.firstSeperator,
			self.editmodeControlContainer,
			self.secondSeperator,
			self.properties,
			self.thirdSeperator,
			self.trash, nil];
}

- (NSArray*)polygonEditToolbarItems
{
	return [NSArray arrayWithObjects:self.pages,
			self.export,
			self.firstSeperator,
			self.editmodeControlContainer,
			self.secondSeperator,
			self.properties,
			self.thirdSeperator,
			self.trash,
			self.finalSeperator,
			self.cancel,
			self.done,
			nil];
}

- (NSArray*)ellipseEditToolbarItems
{
	return [NSArray arrayWithObjects:self.pages,
			self.export,
			self.firstSeperator,
			self.editmodeControlContainer,
			self.secondSeperator,
			self.properties,
			self.thirdSeperator,
			self.trash,
			self.finalSeperator,
			self.cancel,
			nil];
}

- (void)clearGrabHandles
{
	if (self.grabHandles != nil)
	{
		for(GrabHandle* handle in self.grabHandles)
		{
			[handle removeFromSuperview];
		}
		[self.grabHandles removeAllObjects];
		self.grabHandles = nil;
	}
}

- (void)createGrabHandles
{
	[self clearGrabHandles];
	if (_selectedShape != nil)
	{
		self.grabHandles = [[[NSMutableArray alloc] initWithCapacity:_selectedShape.points.count] autorelease];
		for(GraphPaperLocation* location in _selectedShape.points)
		{
			GrabHandle* handle = [[[GrabHandle alloc] initWithController:self graphPaperLocation:location] autorelease];
			[self.graphPaperView addSubview:handle];
			[self.grabHandles addObject:handle];
		}
	}
}

@end


@implementation EditorViewController

@synthesize graphPaperView = _graphPaperView;
@synthesize editMode = _editMode;
@synthesize pages = _pages;
@synthesize editmodeControl = _editmodeControl;
@synthesize properties = _properties;
@synthesize trash = _trash;
@synthesize done = _done;
@synthesize cancel = _cancel;
@synthesize isPlacingPoints = _isPlacingPoints;
@synthesize graphPaper = _graphPaper;
@synthesize grabHandles = _grabHandles;
@synthesize strokeColor = _strokeColor;
@synthesize strokeWidth = _strokeWidth;
@synthesize toolbar = _toolbar;
@synthesize editmodeControlContainer = _editmodeControlContainer;
@synthesize firstSeperator = _firstSeperator;
@synthesize secondSeperator = _secondSeperator;
@synthesize thirdSeperator = _thirdSeperator;
@synthesize finalSeperator = _finalSeperator;
@synthesize selectedShape = _selectedShape;
@synthesize isDraggingShape = _isDraggingShape;
@synthesize oldDragLocation = _oldDragLocation;
@synthesize propertiesViewController = _propertiesViewController;
@synthesize propertiesPopoverController = _propertiesPopoverController;
@synthesize exportViewController = _exportViewController;
@synthesize exportPopoverController = _exportPopoverController;
@synthesize export = _export;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.editMode = emPolygon;
		self.graphPaper = [[[GraphPaper alloc] init] autorelease];
		self.strokeColor = [Color colorWithRed:0.0 green:0.0 blue:0.0];
		self.strokeWidth = 3.0;
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.toolbar setItems:[self defaultToolbarItems]];
	[self setBarButtonStates];
	self.graphPaperView.controller = self;
	self.propertiesViewController = [[[PropertiesViewController alloc] initWithNibName:@"PropertiesViewController" bundle:nil editorViewController:self] autorelease];
	self.propertiesPopoverController = [[[UIPopoverController alloc] initWithContentViewController:self.propertiesViewController] autorelease];
	self.propertiesPopoverController.popoverContentSize = self.propertiesViewController.view.frame.size;
	self.exportViewController = [[[ExportViewController alloc] initWithNibName:@"ExportViewController" bundle:nil editorViewController:self] autorelease];
	self.exportPopoverController = [[[UIPopoverController alloc] initWithContentViewController:self.exportViewController] autorelease];
	self.exportPopoverController.popoverContentSize = self.exportViewController.view.frame.size;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

- (IBAction)editModeChanged:(id)sender
{
	self.editMode = (editModeEnum)self.editmodeControl.selectedSegmentIndex;
	[self setBarButtonStates];
	if (self.editMode != emLayout)
	{
		[self clearGrabHandles];
	}
}

- (void)graphPaperClickedAt:(GraphPaperLocation*)location viewLocation:(CGPoint)viewLocation
{
	if (self.editMode == emLayout)
	{
		BOOL found = NO;
		for(Shape* shape in self.graphPaper.shapes)
		{
			if ([shape containsViewPoint:viewLocation])
			{
				self.oldDragLocation = location;
				self.isDraggingShape = YES;
				self.selectedShape = shape;
				found = YES;
				break;
			}
		}
		if (!found)
			self.selectedShape = nil;
	}
	else
	{
		if (!self.isPlacingPoints)
		{
			self.selectedShape = nil;
			self.isPlacingPoints = YES;
			self.grabHandles = [[[NSMutableArray alloc] init] autorelease];
			if (self.editMode == emPolygon)
			{
				[self.toolbar setItems:[self polygonEditToolbarItems] animated:YES];
			}
			else
			{
				[self.toolbar setItems:[self ellipseEditToolbarItems] animated:YES];
			}

		}
		
		GrabHandle *handle = [[[GrabHandle alloc] initWithController:self graphPaperLocation:location] autorelease];
		[self.graphPaperView addSubview:handle];
		[self.grabHandles addObject:handle];
		[self.graphPaperView setNeedsDisplay];
		
		if (self.editMode == emEllipse && self.grabHandles.count == 2)
		{
			[self doneClicked:nil];
		}
	}
}

- (void)graphPaperDragAt:(GraphPaperLocation*)location viewLocation:(CGPoint)viewLocation
{
	if (self.isDraggingShape)
	{
		if (self.oldDragLocation.x != location.x || self.oldDragLocation.y != location.y)
		{
			int xOffset = location.x - self.oldDragLocation.x;
			int yOffset = location.y - self.oldDragLocation.y;

			[self.selectedShape transformWithX:xOffset y:yOffset];
			for(GrabHandle* handle in self.grabHandles)
			{
				[handle updatePosition];
			}
			self.oldDragLocation = location;
			[self.graphPaperView setNeedsDisplay];
		}
	}
}

- (void)graphPaperReleasedAt:(GraphPaperLocation*)location viewLocation:(CGPoint)viewLocation
{
	self.isDraggingShape = NO;
}

- (IBAction)doneClicked:(id)sender
{
	if (self.isPlacingPoints)
	{
		NSMutableArray* points = nil;
		if (self.grabHandles.count > 1)
		{
			points = [[[NSMutableArray alloc] init] autorelease];
			for(GrabHandle* handle in self.grabHandles)
			{
				[points addObject:handle.graphPaperLocation];
				[handle removeFromSuperview];
			}
		}

		[self.grabHandles removeAllObjects];
		self.grabHandles = nil;
		[self.toolbar setItems:[self defaultToolbarItems] animated:YES];
	
		if (points != nil)
		{
			Shape* newShape = nil;		
			if (self.editMode == emPolygon)
			{
				newShape = [[[Polygon alloc] initWithGraphPaper:self.graphPaper points:points strokeColor:self.strokeColor strokeWidth:self.strokeWidth] autorelease];
			}
			else if (self.editMode == emEllipse)
			{
				newShape = [[[Ellipse alloc] initWithGraphPaper:self.graphPaper points:points strokeColor:self.strokeColor strokeWidth:self.strokeWidth] autorelease];
			}
			
			[self.graphPaper.shapes addObject:newShape];
			[self.graphPaperView setNeedsDisplay];
			self.isPlacingPoints = NO;
			self.selectedShape = newShape;
		}
	}
}

- (IBAction)cancelClicked:(id)sender
{
	self.isPlacingPoints = NO;
	[self clearGrabHandles];
	[self.graphPaperView setNeedsDisplay];
}

- (IBAction)propertiesClicked:(id)sender
{
	[self.propertiesViewController.colorPicker selectColor:self.strokeColor];
	[self.propertiesPopoverController presentPopoverFromBarButtonItem:self.properties permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)exportClicked:(id)sender
{
	[self.exportPopoverController presentPopoverFromBarButtonItem:self.export permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)setSelectedShape:(Shape*)shape
{
	@synchronized(self)
	{
		[_selectedShape release];
		_selectedShape = [shape retain];
		[self createGrabHandles];
		[self setBarButtonStates];
	}
}

- (void)setStrokeColor:(Color *)color
{
	@synchronized(self)
	{
		[_strokeColor release];
		_strokeColor = [color retain];
		
		if (self.selectedShape != nil)
		{
			self.selectedShape.strokeColor = _strokeColor;
			[self.graphPaperView setNeedsDisplay];
		}
	}
}

- (void)setStrokeWidth:(CGFloat)width
{
	@synchronized(self)
	{
		_strokeWidth = width;
		if (self.selectedShape != nil)
		{
			self.selectedShape.strokeWidth = _strokeWidth;
			[self.graphPaperView setNeedsDisplay];
		}
	}
}
		

@end