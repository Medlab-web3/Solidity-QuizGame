// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract QuizGame {
    using Counters for Counters.Counter;

    // Event emitted when a new quiz is launched.
    // It helps in tracking quiz creation and provides details like ID, creator, end time, URI, and price.
    event Launch(
        uint256 id,
        address indexed creator,
        uint256 endAt,
        string uri,
        uint256 price
    );
    event GuessLose(uint256 indexed id, address indexed caller, uint256 price);
    event GuessWin(uint256 indexed id, address indexed caller, uint256 prize);
    event CancelQuiz(uint256 indexed id, address indexed caller);
    event Claim(uint256 id, uint256 pledged);

    struct Quiz {
        address creator;
        bytes32 quizAnswerHash;
        uint256 price;
        uint256 pledged;
        uint256 startAt;
        uint256 endAt;
        string uri;
        address winner;
    }

    IERC20 public immutable token;
    Counters.Counter private quizCounter;
    mapping(uint256 => Quiz) public quizes;

    // Constructor to initialize the contract with the address of an ERC20 token.
    // The token address is validated to ensure it's not the zero address, providing security against incorrect deployment.
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    modifier checkIsPlayable(uint256 _id) {
        Quiz storage quiz = quizes[_id];
        require(block.timestamp <= quiz.endAt, "Quiz has ended");
        require(quiz.creator != msg.sender, "Cannot play your own quiz");
        require(quiz.winner == address(0), "Quiz already has a winner");
        _;
    }

    modifier checkAnswerValid(bytes32 _quizAnswerHash) {
        require(_quizAnswerHash != bytes32(0), "Answer hash cannot be empty");
        _;
    }

    /**
     * @notice Launch a new quiz.
     * @param _quizAnswerHash The hashed answer to the quiz. Must be a valid non-empty hash.
     * @param _endAt The timestamp at which the quiz ends. Must be in the future and within the allowed duration.
     * @param _price The minimum amount participants need to pay to attempt the quiz.
     * @param _uri The URI containing quiz details such as the question, description, and associated image.
     */
    function launch(
        bytes32 _quizAnswerHash,
        uint256 _endAt,
        uint256 _price,
        string calldata _uri
    ) external checkAnswerValid(_quizAnswerHash) {
        require(_endAt > block.timestamp, "End time must be in the future");
        require(_endAt <= block.timestamp + 90 days, "Exceeds max duration");

        uint256 id = quizCounter.current();
        quizes[id] = Quiz({
            creator: msg.sender,
            quizAnswerHash: _quizAnswerHash,
            price: _price,
            pledged: 0,
            startAt: block.timestamp,
            endAt: _endAt,
            uri: _uri,
            winner: address(0)
        });

        quizCounter.increment();
        emit Launch(id, msg.sender, _endAt, _uri, _price);
    }

    /**
     * @notice Guess the answer to a quiz.
     * @param _id The ID of the quiz being attempted.
     * @param _answer The answer provided by the participant.
     * @dev If the provided answer matches the stored answer hash, the participant wins and receives the pledged amount.
     * If the answer does not match, the participant loses, and the pledged amount remains.
     */
    function guess(uint256 _id, string calldata _answer)
        external
        payable
        checkIsPlayable(_id)
    {
        Quiz storage quiz = quizes[_id];
        require(msg.value >= quiz.price, "Insufficient payment");

        quiz.pledged += msg.value;

        // Check if the provided answer matches the stored answer hash.
        if (keccak256(abi.encodePacked(_answer)) == quiz.quizAnswerHash) {
            quiz.winner = msg.sender; // Mark the participant as the winner.
            token.transfer(msg.sender, quiz.pledged); // Transfer the pledged amount to the winner.
            emit GuessWin(_id, msg.sender, quiz.pledged);
        } else {
            emit GuessLose(_id, msg.sender, quiz.price); // Emit an event indicating the participant lost.
        }
    }

    function claimMoney(uint256 _id) external {
        Quiz storage quiz = quizes[_id];
        require(msg.sender == quiz.creator, "Not the creator");
        require(block.timestamp > quiz.endAt, "Quiz not ended");
        require(quiz.winner == address(0), "Quiz already has a winner");

        uint256 pledgedAmount = quiz.pledged;
        quiz.pledged = 0;
        token.transfer(quiz.creator, pledgedAmount);

        emit Claim(_id, pledgedAmount);
    }

    /**
     * @notice Returns all quizzes as an array.
     * @dev This function iterates over all stored quizzes and might be expensive in terms of gas if the dataset is large.
     * Consider using pagination or filtering techniques for better scalability when the number of quizzes grows significantly.
     */
    function viewAllQuizes() external view returns (Quiz[] memory) {
        uint256 totalQuizes = quizCounter.current();
        Quiz[] memory allQuizes = new Quiz[](totalQuizes);

        for (uint256 i = 0; i < totalQuizes; i++) {
            allQuizes[i] = quizes[i];
        }

        return allQuizes;
    }
}
