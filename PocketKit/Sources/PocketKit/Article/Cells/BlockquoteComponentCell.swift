import UIKit


class BlockquoteComponentCell: UICollectionViewCell, ArticleComponentTextCell, ArticleComponentTextViewDelegate {
    
    struct Constants {
        static let dividerWidth: CGFloat = 6
        static let stackSpacing: CGFloat = 12
    }
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(.ui.grey6)
        return view
    }()
    
    private lazy var textView: ArticleComponentTextView = {
        let textView = ArticleComponentTextView()
        textView.actionDelegate = self
        return textView
    }()
    
    private lazy var stackView: UIStackView = {
       let stackView = UIStackView(arrangedSubviews: [divider, textView])
        stackView.spacing = Constants.stackSpacing
        stackView.alignment = .center
        return stackView
    }()
    
    var attributedBlockquote: NSAttributedString? {
        get {
            textView.attributedText
        }
        set {
            textView.attributedText = newValue
        }
    }
    
    weak var delegate: ArticleComponentTextCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(stackView)

        divider.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: Constants.dividerWidth),
            divider.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("Unable to instantiate \(Self.self) from xib/storyboard")
    }
}