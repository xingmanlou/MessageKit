// MIT License
//
// Copyright (c) 2017-2022 MessageKit
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit


/// A subclass of `MessageCollectionViewCell` used to display text, media, and location messages.
open class MessageContentCell: MessageCollectionViewCell,UIContextMenuInteractionDelegate {
    
    func takeScreenshot(view: UIView) -> UIImage? {
        
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            return renderer.image { context in
                // 绘制透明背景
                context.cgContext.clear(view.bounds)

                // 保存当前状态
                context.cgContext.saveGState()

                // 应用 mask
                if let maskLayer = view.layer.mask {
                    context.cgContext.addRect(view.bounds)
                    context.cgContext.clip() // 应用 mask

                    // 渲染 UIImageView 的内容
                    view.layer.render(in: context.cgContext)
                }

                // 恢复状态
                context.cgContext.restoreGState()
            }
        
//        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        view.layer.render(in: context)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        return image
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let actionList = self.delegate?.menuActionList(in: self),actionList.count > 0 else {
            return nil
        }
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: {[weak self] () -> UIViewController? in
            guard let self = self,
                  let image = self.takeScreenshot(view: self.messageContainerView) else {
                return nil
            }
            // 创建并返回自定义预览视图控制器
            let previewController = UIViewController()
            
            let imageView = UIImageView(image: image)
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.backgroundColor = .clear
            previewController.preferredContentSize = CGSizeMake(self.messageContainerView.bounds.width + 10, self.messageContainerView.bounds.height + 10)
            previewController.view.backgroundColor = .lightGray
//            previewController.view.layer.cornerRadius = 0
//            previewController.view.layer.masksToBounds = true
            
            let blurEffect = UIBlurEffect(style: .light) // 可以选择 .light 或 .dark
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(blurEffectView)
            sendSubviewToBack(blurEffectView)
            
            previewController.view.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: previewController.view.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: previewController.view.centerYAnchor)
            ])
            
            return previewController
                        
        }) { suggestedActions in
            return UIMenu(title: "", children: actionList)
        }
        return configuration
    }
  // MARK: Lifecycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    setupSubviews()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    setupSubviews()
  }

  // MARK: Open

  /// The image view displaying the avatar.
  open var avatarView = AvatarView()

  /// The container used for styling and holding the message's content view.
  open var messageContainerView: MessageContainerView = {
    let containerView = MessageContainerView()
    containerView.clipsToBounds = true
      containerView.isUserInteractionEnabled = true
//      containerView.backgroundColor = .clear
    containerView.layer.masksToBounds = true
    return containerView
  }()

  /// The top label of the cell.
  open var cellTopLabel: InsetLabel = {
    let label = InsetLabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
  }()

  /// The bottom label of the cell.
  open var cellBottomLabel: InsetLabel = {
    let label = InsetLabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
  }()

  /// The top label of the messageBubble.
  open var messageTopLabel: InsetLabel = {
    let label = InsetLabel()
    label.numberOfLines = 0
    return label
  }()

  /// The bottom label of the messageBubble.
  open var messageBottomLabel: InsetLabel = {
    let label = InsetLabel()
    label.numberOfLines = 0
    return label
  }()

  /// The time label of the messageBubble.
  open var messageTimestampLabel = InsetLabel()

  // Should only add customized subviews - don't change accessoryView itself.
  open var accessoryView = UIView()

  /// The `MessageCellDelegate` for the cell.
  open weak var delegate: MessageCellDelegate?

  open override func prepareForReuse() {
    super.prepareForReuse()
    cellTopLabel.text = nil
    cellBottomLabel.text = nil
    messageTopLabel.text = nil
    messageBottomLabel.text = nil
    messageTimestampLabel.attributedText = nil
  }

  open func setupSubviews() {
    contentView.addSubviews(
      accessoryView,
      cellTopLabel,
      messageTopLabel,
      messageBottomLabel,
      cellBottomLabel,
      messageContainerView,
      avatarView,
      messageTimestampLabel)
      let interaction = UIContextMenuInteraction(delegate: self)
      messageContainerView.addInteraction(interaction)
  }

  // MARK: - Configuration

  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    guard let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes else { return }
    // Call this before other laying out other subviews
    layoutMessageContainerView(with: attributes)
    layoutMessageBottomLabel(with: attributes)
    layoutCellBottomLabel(with: attributes)
    layoutCellTopLabel(with: attributes)
    layoutMessageTopLabel(with: attributes)
    layoutAvatarView(with: attributes)
    layoutAccessoryView(with: attributes)
    layoutTimeLabelView(with: attributes)
  }

  /// Used to configure the cell.
  ///
  /// - Parameters:
  ///   - message: The `MessageType` this cell displays.
  ///   - indexPath: The `IndexPath` for this cell.
  ///   - messagesCollectionView: The `MessagesCollectionView` in which this cell is contained.
  open func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
    guard let dataSource = messagesCollectionView.messagesDataSource else {
      fatalError(MessageKitError.nilMessagesDataSource)
    }
    guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
      fatalError(MessageKitError.nilMessagesDisplayDelegate)
    }

    delegate = messagesCollectionView.messageCellDelegate

    let messageColor = displayDelegate.backgroundColor(for: message, at: indexPath, in: messagesCollectionView)
    let messageStyle = displayDelegate.messageStyle(for: message, at: indexPath, in: messagesCollectionView)

    displayDelegate.configureAvatarView(avatarView, for: message, at: indexPath, in: messagesCollectionView)

    displayDelegate.configureAccessoryView(accessoryView, for: message, at: indexPath, in: messagesCollectionView)

    messageContainerView.backgroundColor = messageColor
    messageContainerView.style = messageStyle

    let topCellLabelText = dataSource.cellTopLabelAttributedText(for: message, at: indexPath)
    let bottomCellLabelText = dataSource.cellBottomLabelAttributedText(for: message, at: indexPath)
    let topMessageLabelText = dataSource.messageTopLabelAttributedText(for: message, at: indexPath)
    let bottomMessageLabelText = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath)
    let messageTimestampLabelText = dataSource.messageTimestampLabelAttributedText(for: message, at: indexPath)
    cellTopLabel.attributedText = topCellLabelText
    cellBottomLabel.attributedText = bottomCellLabelText
    messageTopLabel.attributedText = topMessageLabelText
    messageBottomLabel.attributedText = bottomMessageLabelText
    messageTimestampLabel.attributedText = messageTimestampLabelText
    messageTimestampLabel.isHidden = !messagesCollectionView.showMessageTimestampOnSwipeLeft
      
  }
    
    open func updateCellStatus(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView){
        
        guard let dataSource = messagesCollectionView.messagesDataSource else {
          fatalError(MessageKitError.nilMessagesDataSource)
        }
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
          fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }

        displayDelegate.configureAccessoryView(accessoryView, for: message, at: indexPath, in: messagesCollectionView)
        let bottomMessageLabelText = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath)
        messageBottomLabel.attributedText = bottomMessageLabelText
    }

  /// Handle tap gesture on contentView and its subviews.
  open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
    let touchLocation = gesture.location(in: self)

    switch true {
    case messageContainerView.frame
      .contains(touchLocation) && !cellContentView(canHandle: convert(touchLocation, to: messageContainerView)):
      delegate?.didTapMessage(in: self)
    case avatarView.frame.contains(touchLocation):
      delegate?.didTapAvatar(in: self)
    case cellTopLabel.frame.contains(touchLocation):
      delegate?.didTapCellTopLabel(in: self)
    case cellBottomLabel.frame.contains(touchLocation):
      delegate?.didTapCellBottomLabel(in: self)
    case messageTopLabel.frame.contains(touchLocation):
      delegate?.didTapMessageTopLabel(in: self)
    case messageBottomLabel.frame.contains(touchLocation):
      delegate?.didTapMessageBottomLabel(in: self)
    case accessoryView.frame.contains(touchLocation):
      delegate?.didTapAccessoryView(in: self)
    default:
      delegate?.didTapBackground(in: self)
    }
  }

  /// Handle long press gesture, return true when gestureRecognizer's touch point in `messageContainerView`'s frame
  open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let touchPoint = gestureRecognizer.location(in: self)
    guard gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) else { return false }
    return messageContainerView.frame.contains(touchPoint)
  }

  /// Handle `ContentView`'s tap gesture, return false when `ContentView` doesn't needs to handle gesture
  open func cellContentView(canHandle _: CGPoint) -> Bool {
    false
  }

  // MARK: - Origin Calculations

  /// Positions the cell's `AvatarView`.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutAvatarView(with attributes: MessagesCollectionViewLayoutAttributes) {
    var origin: CGPoint = .zero
    let padding = attributes.avatarLeadingTrailingPadding

    switch attributes.avatarPosition.horizontal {
    case .cellLeading:
      origin.x = padding
    case .cellTrailing:
      origin.x = attributes.frame.width - attributes.avatarSize.width - padding
    case .natural:
      fatalError(MessageKitError.avatarPositionUnresolved)
    }

    switch attributes.avatarPosition.vertical {
    case .messageLabelTop:
      origin.y = messageTopLabel.frame.minY
    case .messageTop: // Needs messageContainerView frame to be set
      origin.y = messageContainerView.frame.minY
    case .messageBottom: // Needs messageContainerView frame to be set
      origin.y = messageContainerView.frame.maxY - attributes.avatarSize.height
    case .messageCenter: // Needs messageContainerView frame to be set
      origin.y = messageContainerView.frame.midY - (attributes.avatarSize.height / 2)
    case .cellBottom:
      origin.y = attributes.frame.height - attributes.avatarSize.height
    default:
      break
    }

    avatarView.frame = CGRect(origin: origin, size: attributes.avatarSize)
  }

  /// Positions the cell's `MessageContainerView`.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutMessageContainerView(with attributes: MessagesCollectionViewLayoutAttributes) {
    var origin: CGPoint = .zero

    switch attributes.avatarPosition.vertical {
    case .messageBottom:
      origin.y = attributes.size.height - attributes.messageContainerPadding.bottom - attributes.cellBottomLabelSize
        .height - attributes.messageBottomLabelSize.height - attributes.messageContainerSize.height - attributes
        .messageContainerPadding.top
    case .messageCenter:
      if attributes.avatarSize.height > attributes.messageContainerSize.height {
        let messageHeight = attributes.messageContainerSize.height + attributes.messageContainerPadding.vertical
        origin.y = (attributes.size.height / 2) - (messageHeight / 2)
      } else {
        fallthrough
      }
    default:
      if attributes.accessoryViewSize.height > attributes.messageContainerSize.height {
        let messageHeight = attributes.messageContainerSize.height + attributes.messageContainerPadding.vertical
        origin.y = (attributes.size.height / 2) - (messageHeight / 2)
      } else {
        origin.y = attributes.cellTopLabelSize.height + attributes.messageTopLabelSize.height + attributes
          .messageContainerPadding.top
      }
    }

    let avatarPadding = attributes.avatarLeadingTrailingPadding
    switch attributes.avatarPosition.horizontal {
    case .cellLeading:
      origin.x = attributes.avatarSize.width + attributes.messageContainerPadding.left + avatarPadding
    case .cellTrailing:
      origin.x = attributes.frame.width - attributes.avatarSize.width - attributes.messageContainerSize.width - attributes
        .messageContainerPadding.right - avatarPadding
    case .natural:
      fatalError(MessageKitError.avatarPositionUnresolved)
    }

    messageContainerView.frame = CGRect(origin: origin, size: attributes.messageContainerSize)
  }

  /// Positions the cell's top label.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutCellTopLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
    cellTopLabel.textAlignment = attributes.cellTopLabelAlignment.textAlignment
    cellTopLabel.textInsets = attributes.cellTopLabelAlignment.textInsets

    cellTopLabel.frame = CGRect(origin: .zero, size: attributes.cellTopLabelSize)
  }

  /// Positions the cell's bottom label.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutCellBottomLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
    cellBottomLabel.textAlignment = attributes.cellBottomLabelAlignment.textAlignment
    cellBottomLabel.textInsets = attributes.cellBottomLabelAlignment.textInsets

    let y = messageBottomLabel.frame.maxY
    let origin = CGPoint(x: 0, y: y)

    cellBottomLabel.frame = CGRect(origin: origin, size: attributes.cellBottomLabelSize)
  }

  /// Positions the message bubble's top label.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutMessageTopLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
    messageTopLabel.textAlignment = attributes.messageTopLabelAlignment.textAlignment
    messageTopLabel.textInsets = attributes.messageTopLabelAlignment.textInsets

    let y = messageContainerView.frame.minY - attributes.messageContainerPadding.top - attributes.messageTopLabelSize.height
    let origin = CGPoint(x: 0, y: y)

    messageTopLabel.frame = CGRect(origin: origin, size: attributes.messageTopLabelSize)
  }

  /// Positions the message bubble's bottom label.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutMessageBottomLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
    messageBottomLabel.textAlignment = attributes.messageBottomLabelAlignment.textAlignment
    messageBottomLabel.textInsets = attributes.messageBottomLabelAlignment.textInsets

    let y = messageContainerView.frame.maxY + attributes.messageContainerPadding.bottom
    let origin = CGPoint(x: 0, y: y)

    messageBottomLabel.frame = CGRect(origin: origin, size: attributes.messageBottomLabelSize)
  }

  /// Positions the cell's accessory view.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutAccessoryView(with attributes: MessagesCollectionViewLayoutAttributes) {
    var origin: CGPoint = .zero

    // Accessory view is set at the side space of the messageContainerView
    switch attributes.accessoryViewPosition {
    case .messageLabelTop:
      origin.y = messageTopLabel.frame.minY
    case .messageTop:
      origin.y = messageContainerView.frame.minY
    case .messageBottom:
      origin.y = messageContainerView.frame.maxY - attributes.accessoryViewSize.height
    case .messageCenter:
      origin.y = messageContainerView.frame.midY - (attributes.accessoryViewSize.height / 2)
    case .cellBottom:
      origin.y = attributes.frame.height - attributes.accessoryViewSize.height
    default:
      break
    }

    // Accessory view is always on the opposite side of avatar
    switch attributes.avatarPosition.horizontal {
    case .cellLeading:
      origin.x = messageContainerView.frame.maxX + attributes.accessoryViewPadding.left
    case .cellTrailing:
      origin.x = messageContainerView.frame.minX - attributes.accessoryViewPadding.right - attributes.accessoryViewSize
        .width
    case .natural:
      fatalError(MessageKitError.avatarPositionUnresolved)
    }

    accessoryView.frame = CGRect(origin: origin, size: attributes.accessoryViewSize)
  }

  ///  Positions the message bubble's time label.
  /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
  open func layoutTimeLabelView(with attributes: MessagesCollectionViewLayoutAttributes) {
    let paddingLeft: CGFloat = 10
    let origin = CGPoint(
        x: self.frame.maxX + paddingLeft,
        y: messageContainerView.frame.minY + messageContainerView.frame.height * 0.5 - messageTimestampLabel.font.ascender * 0.5)
    let size = CGSize(width: attributes.messageTimeLabelSize.width, height: attributes.messageTimeLabelSize.height)
    messageTimestampLabel.frame = CGRect(origin: origin, size: size)
  }
}
