//
//  QuizViewController.swift
//  QuizApp
//
//  Created by Anil Guven on 16/09/2023.
//

import UIKit

class QuizViewController: UIViewController {
    
    // MARK: - UI Elements
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var hintLabel: UILabel!
    
    lazy var thumbIconImageView: UIImageView = {
        let iconName = "hand.thumbsdown.fill"
        let iconConfig = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 46, weight: .semibold)
        )
        
        let view = UIImageView()
        view.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tintColor = .systemRed
        
        return view
    }()
    
    // MARK: - Properties
    var questions = [Question]()
    var currentQuestionIndex = 0
    var numberOfCorrectAnswers = 0
    var numberOfIncorrectAnswers = 0
    let numberOfQuestionsInQuiz = 10
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        prepareQuestions()
        prepareUIForQuestion(at: currentQuestionIndex)
        textField.becomeFirstResponder()
    }
    
    // MARK: - Methods
    func setupViews() {
        imageView.addSubview(thumbIconImageView)
        thumbIconImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        thumbIconImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        setshowsThumbIcon(shows: false)
    }
    
    func prepareQuestions() {
        if let jsonPath = Bundle.main.path(forResource: "Questions", ofType: "json") {
            let jsonUrl = URL(fileURLWithPath: jsonPath)
            
            do {
                let jsonData = try Data(contentsOf: jsonUrl)
                let decoder = JSONDecoder()
                let questions = try decoder.decode([Question].self, from: jsonData)
                
                var questionDeck = Set<Question>()
                
                for _ in 1...numberOfQuestionsInQuiz {
                    var randomQuestion = questions.randomElement()!
                    
                    while questionDeck.contains(randomQuestion) {
                        randomQuestion = questions.randomElement()!
                    }
                    
                    questionDeck.insert(randomQuestion)
                }
                
                self.questions = Array(questionDeck)
            } catch {
                print(error)
            }
        }
    }
    
    func prepareUIForQuestion(at index: Int) {
        let question = questions[index]
        
        // Updating the title
        titleLabel.text = "Question \(index + 1) of \(questions.count)"
        
        // Updates the score label
        if numberOfCorrectAnswers + numberOfIncorrectAnswers == 0 {
            // No answers given yet.
            scoreLabel.text = "No Answers"
        } else {
            scoreLabel.text = "\(numberOfCorrectAnswers) Correct, \(numberOfIncorrectAnswers) Wrong"
        }
        
        // Updating the image
        let imageUrl =
        "https://source.unsplash.com/random/1920×1080/?\(question.imageName)&orientation=landscape"
        if let imageRequestUrl = URL(string: imageUrl) {
            let request = URLRequest(url: imageRequestUrl)
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let data {
                    let image = UIImage(data: data)
                    
                    DispatchQueue.main.async {
                        UIView.transition(with: self.imageView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                            self.imageView.image = image
                        }, completion: nil)
                    }
                }
            }.resume()
        }
        
        // Emptying the TextField
        textField.text = nil
        
        // Hiding the hint label
        hintLabel.isHidden = true
        
        // Updating the hint value
        hintLabel.text = question.hint
    }
    
    func checkQuestionAnswer(questionIndex: Int, userAnswer: String) -> Bool {
        let question = questions[questionIndex]
        let correctAnswer = question.answer
        
        if userAnswer.lowercased() == correctAnswer.lowercased() {
            numberOfCorrectAnswers += 1
            return true
        } else {
            numberOfIncorrectAnswers += 1
            return false
        }
    }
    
    func setshowsThumbIcon(shows: Bool, isUp: Bool = true) {
        var iconName: String!
        let iconConfig = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 46, weight: .semibold)
        )
        
        if isUp {
            iconName = "hand.thumbsup.fill"
            thumbIconImageView.tintColor = .systemGreen
        } else {
            iconName = "hand.thumbsdown.fill"
            thumbIconImageView.tintColor = .systemRed
        }
        
        thumbIconImageView.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
        thumbIconImageView.transform = .init(
            scaleX: 0.8, y: 0.8
        ).concatenating(.init(
            rotationAngle: isUp ? -.pi / 4 : .pi / 4)
        )
        
        let animation = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.25) {
            self.thumbIconImageView.alpha = shows ? 1 : 0
            self.thumbIconImageView.transform = .identity
        }
        
        animation.addCompletion { completed in
            UIViewPropertyAnimator(duration: 1, dampingRatio: 1) {
                self.thumbIconImageView.alpha = 0
            }.startAnimation()
        }
        
        animation.startAnimation()
    }
    
    // MARK: - Actions
    @IBAction func hintButtonTapped() {
        UIViewPropertyAnimator(duration: 0.35, curve: .easeInOut, animations: {
            self.hintLabel.isHidden = false
        }).startAnimation()
        
        // GCD: Grand Central Dispatch
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            UIViewPropertyAnimator(duration: 0.35, curve: .easeInOut, animations: {
                self.hintLabel.isHidden = true
            }).startAnimation()
        })
    }
    
    @IBAction func nextButtonTapped() {
        let userAnswer = textField.text!
        
        // Text Input Control
        guard userAnswer.isEmpty == false else {
            let alert = UIAlertController(title: "No Guess", message: "Give me your guess.", preferredStyle: .alert)
            let doneAction = UIAlertAction(title: "Done", style: .default)
            
            alert.addAction(doneAction)
            
            present(alert, animated: true)
            
            return
        }
        
        let isCorrectAnswer = checkQuestionAnswer(
            questionIndex: currentQuestionIndex,
            userAnswer: userAnswer
        )
        
        setshowsThumbIcon(shows: true, isUp: isCorrectAnswer)
        
        // Check if the game is over
        guard currentQuestionIndex + 1 < questions.count else {
            prepareUIForQuestion(at: currentQuestionIndex)
            
            let alert = UIAlertController(title: "Game Over", message: "\(numberOfCorrectAnswers) Correct, \(numberOfIncorrectAnswers) Wrong", preferredStyle: .alert)
            
            let playAgainAction = UIAlertAction(title: "Play Again", style: .default) { _ in
                // Code block that will execute when the button is clicked
                self.currentQuestionIndex = 0
                self.numberOfCorrectAnswers = 0
                self.numberOfIncorrectAnswers = 0
                
                self.prepareQuestions()
                self.prepareUIForQuestion(at: self.currentQuestionIndex)
            }
            
            alert.addAction(playAgainAction)
            
            present(alert, animated: true)
            
            return
        }
        
        // The game continues, prepare the UI for the next question
        prepareUIForQuestion(at: currentQuestionIndex + 1)
        currentQuestionIndex += 1
    }
}
