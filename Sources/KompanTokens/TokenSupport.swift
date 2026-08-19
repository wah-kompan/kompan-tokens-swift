//
// TokenSupport.swift
//
// Do not edit directly, this file was auto-generated.
//
// The types the generated constants are written against. A gradient and a shadow
// are not values on this platform, so each ships as a small description plus the
// code that renders it — the arithmetic that turns a CSS angle into
// `CAGradientLayer` endpoints, and the `shadowPath` that gives `CALayer` the
// spread it does not have, belong here rather than in every consumer.

import UIKit

extension Tokens {
    /// A colour stop, as `0xRRGGBBAA` — the byte order the Figma export writes.
    public struct GradientStop {
        public let color: UIColor
        /// Position along the gradient line, 0 to 1.
        public let location: CGFloat

        public init(_ rgba: UInt32, at location: CGFloat) {
            self.color = UIColor(
                red: CGFloat((rgba >> 24) & 0xFF) / 255,
                green: CGFloat((rgba >> 16) & 0xFF) / 255,
                blue: CGFloat((rgba >> 8) & 0xFF) / 255,
                alpha: CGFloat(rgba & 0xFF) / 255
            )
            self.location = location
        }
    }

    public struct Gradient {
        /// CSS convention, which is what the Figma style names carry: 0° points
        /// up and the angle increases clockwise, so 180° is top-to-bottom.
        public let angle: CGFloat
        public let stops: [GradientStop]

        public init(angle: CGFloat, stops: [GradientStop]) {
            self.angle = angle
            self.stops = stops
        }

        /// Where the gradient line enters and leaves a box of `size`, in the unit
        /// coordinate space `CAGradientLayer` uses.
        ///
        /// This is why the angle is shipped instead of a precomputed pair of
        /// points: the mapping depends on the aspect ratio. Baking the endpoints
        /// for a square would shear every non-axis-aligned gradient by however
        /// much the real layer is not square. The line is centred on the box and
        /// long enough to cover it, per the CSS `linear-gradient` definition.
        public func endpoints(for size: CGSize) -> (start: CGPoint, end: CGPoint) {
            let radians = angle * .pi / 180
            let dx = sin(radians)
            let dy = -cos(radians)
            // An empty layer draws nothing, but dividing by its width would put
            // an infinity into `startPoint` and Core Animation keeps it.
            let width = size.width > 0 ? size.width : 1
            let height = size.height > 0 ? size.height : 1
            let length = abs(width * dx) + abs(height * dy)
            let halfX = length * dx / 2 / width
            let halfY = length * dy / 2 / height
            return (
                CGPoint(x: 0.5 - halfX, y: 0.5 - halfY),
                CGPoint(x: 0.5 + halfX, y: 0.5 + halfY)
            )
        }

        /// Configure an existing layer, using its current bounds for the angle.
        public func apply(to layer: CAGradientLayer) {
            let (start, end) = endpoints(for: layer.bounds.size)
            // Every property set here is animatable, so an assignment during
            // layout would otherwise start an implicit quarter-second animation.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.colors = stops.map { $0.color.cgColor }
            layer.locations = stops.map { NSNumber(value: Double($0.location)) }
            layer.startPoint = start
            layer.endPoint = end
            CATransaction.commit()
        }

        /// A layer that keeps its angle correct as it is resized.
        public func makeLayer() -> GradientLayer {
            return GradientLayer(self)
        }
    }

    /// A `CAGradientLayer` that recomputes its endpoints whenever it is laid out.
    ///
    /// Without this a consumer has to remember to reapply the gradient from
    /// `layoutSubviews`, and forgetting looks like a design bug rather than a
    /// missing call — the gradient is simply at the wrong angle.
    public final class GradientLayer: CAGradientLayer {
        public var gradient: Gradient? {
            didSet { setNeedsLayout() }
        }

        public convenience init(_ gradient: Gradient) {
            self.init()
            self.gradient = gradient
        }

        public override func layoutSublayers() {
            super.layoutSublayers()
            gradient?.apply(to: self)
        }
    }

    /// One layer of a shadow stack, in points.
    public struct Shadow {
        public let color: UIColor
        public let offset: CGSize
        /// The CSS blur radius, as authored.
        public let blur: CGFloat
        /// How much the shadow's shape grows beyond the box. Negative values
        /// shrink it, which is how the tighter layers of a stack are made.
        public let spread: CGFloat
        public let isInset: Bool

        /// Core Animation blurs with a Gaussian of this radius; CSS specifies
        /// twice it. Passing the CSS number straight to `shadowRadius` is the
        /// usual reason a ported shadow looks too soft.
        public var shadowRadius: CGFloat { return blur / 2 }

        public init(
            _ rgba: UInt32,
            x: CGFloat = 0,
            y: CGFloat = 0,
            blur: CGFloat = 0,
            spread: CGFloat = 0,
            inset: Bool = false
        ) {
            self.color = UIColor(
                red: CGFloat((rgba >> 24) & 0xFF) / 255,
                green: CGFloat((rgba >> 16) & 0xFF) / 255,
                blue: CGFloat((rgba >> 8) & 0xFF) / 255,
                alpha: CGFloat(rgba & 0xFF) / 255
            )
            self.offset = CGSize(width: x, height: y)
            self.blur = blur
            self.spread = spread
            self.isInset = inset
        }

        /// The layer that draws this one shadow behind `bounds`.
        ///
        /// `shadowPath` rather than the layer's own shape, because that is the
        /// only place spread can go: Core Animation has no equivalent property,
        /// and inflating the path by `spread` is exactly what CSS defines spread
        /// to mean.
        fileprivate func makeLayer(bounds: CGRect, cornerRadius: CGFloat) -> CALayer {
            let local = CGRect(origin: .zero, size: bounds.size)
            let layer = CAShapeLayer()
            layer.frame = bounds
            layer.shadowColor = color.cgColor
            layer.shadowOffset = offset
            layer.shadowRadius = shadowRadius
            // The alpha is already in the colour, so opacity stays at 1 rather
            // than being applied twice.
            layer.shadowOpacity = 1
            layer.fillColor = UIColor.clear.cgColor

            if isInset {
                // An inner shadow is the shadow cast by everything *outside* the
                // shape, so the caster is a plane with the shape punched out of
                // it, and the result is clipped back to the shape.
                let hole = UIBezierPath(
                    roundedRect: local.insetBy(dx: spread, dy: spread),
                    cornerRadius: max(0, cornerRadius - spread)
                )
                // Far enough out that the plane's own edge never blurs into view:
                // a small box with a wide shadow needs more margin than its size.
                let reach = blur * 2 + spread + max(abs(offset.width), abs(offset.height))
                let margin = max(local.width, local.height) + reach
                let plane = UIBezierPath(rect: local.insetBy(dx: -margin, dy: -margin))
                plane.append(hole)
                layer.path = plane.cgPath
                layer.fillRule = .evenOdd
                layer.fillColor = UIColor.black.cgColor
                layer.shadowPath = hole.cgPath

                let mask = CAShapeLayer()
                mask.path = UIBezierPath(roundedRect: local, cornerRadius: cornerRadius).cgPath
                layer.mask = mask
            } else {
                layer.shadowPath = UIBezierPath(
                    roundedRect: local.insetBy(dx: -spread, dy: -spread),
                    cornerRadius: max(0, cornerRadius + spread)
                ).cgPath
            }
            return layer
        }
    }

    /// A shadow token: one or more layers, front-most first.
    public struct ShadowStyle {
        /// Paint order, matching CSS — `layers[0]` is drawn on top of the rest.
        public let layers: [Shadow]

        public init(_ layers: [Shadow]) {
            self.layers = layers
        }

        /// Layers rendering the whole stack, back-most first.
        ///
        /// Returned in insertion order because `CALayer` has one shadow and this
        /// design system stacks up to five. Add them under the view's own content
        /// in the order given.
        public func makeLayers(bounds: CGRect, cornerRadius: CGFloat = 0) -> [CALayer] {
            return layers.reversed().map { $0.makeLayer(bounds: bounds, cornerRadius: cornerRadius) }
        }

        /// Replace the shadow layers already inserted into `layer` with this stack.
        ///
        /// Marked so they can be found again: applying a style twice — on every
        /// `layoutSubviews`, say — would otherwise pile stacks on top of each
        /// other until the shadow went black.
        public func apply(to layer: CALayer, cornerRadius: CGFloat = 0) {
            for old in layer.sublayers ?? [] where old.name == ShadowStyle.layerName {
                old.removeFromSuperlayer()
            }
            // Front-most first, each inserted at the bottom, so the back-most
            // layer ends up drawn first.
            for shadow in makeLayers(bounds: layer.bounds, cornerRadius: cornerRadius).reversed() {
                shadow.name = ShadowStyle.layerName
                layer.insertSublayer(shadow, at: 0)
            }
        }

        fileprivate static let layerName = "Tokens.ShadowStyle"
    }
}
