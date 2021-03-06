// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

internal struct ASHostingControllerModifier: ViewModifier
{
	var invalidateCellLayout: (() -> Void) = {}
	func body(content: Content) -> some View
	{
		content
			.environment(\.invalidateCellLayout, invalidateCellLayout)
	}
}

internal protocol ASHostingControllerProtocol
{
	var viewController: UIViewController { get }
	func applyModifier(_ modifier: ASHostingControllerModifier)
	func sizeThatFits(in size: CGSize, selfSizeHorizontal: Bool, selfSizeVertical: Bool) -> CGSize
}

internal class ASHostingController<ViewType: View>: ASHostingControllerProtocol
{
	init(_ view: ViewType)
	{
		hostedView = view
		uiHostingController = .init(rootView: view.modifier(ASHostingControllerModifier()))
	}

	let uiHostingController: UIHostingController<ModifiedContent<ViewType, ASHostingControllerModifier>>
	var viewController: UIViewController
	{
		uiHostingController.view.backgroundColor = .clear
		uiHostingController.view.insetsLayoutMarginsFromSafeArea = false
		return uiHostingController as UIViewController
	}

	var hostedView: ViewType
	var modifier: ASHostingControllerModifier = ASHostingControllerModifier()
	{
		didSet
		{
			uiHostingController.rootView = hostedView.modifier(modifier)
		}
	}

	func setView(_ view: ViewType)
	{
		hostedView = view
		uiHostingController.rootView = hostedView.modifier(modifier)
	}

	func applyModifier(_ modifier: ASHostingControllerModifier)
	{
		self.modifier = modifier
	}

	func sizeThatFits(in size: CGSize, selfSizeHorizontal: Bool, selfSizeVertical: Bool) -> CGSize
	{
		let fittingSize = CGSize(
			width: selfSizeHorizontal ? .infinity : size.width,
			height: selfSizeVertical ? .infinity : size.height)
		// Find the desired size
		var desiredSize = uiHostingController.sizeThatFits(in: fittingSize)

		// Accounting for 'greedy' swiftUI views that take up as much space as they can
		switch (desiredSize.width, desiredSize.height)
		{
		case (.infinity, .infinity):
			desiredSize = uiHostingController.sizeThatFits(in: size)
		case (.infinity, _):
			desiredSize = uiHostingController.sizeThatFits(in: CGSize(width: size.width, height: fittingSize.height))
		case (_, .infinity):
			desiredSize = uiHostingController.sizeThatFits(in: CGSize(width: fittingSize.width, height: size.height))
		default: break
		}

		// Ensure correct dimensions in non-self sizing axes
		if !selfSizeHorizontal { desiredSize.width = size.width }
		if !selfSizeVertical { desiredSize.height = size.height }

		return desiredSize
	}
}
