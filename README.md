# Solidity-QuizGame

QuizGame is a Solidity-based smart contract that facilitates a blockchain-based quiz competition where users can create quizzes, participate by submitting answers, and earn rewards. The contract is designed to be interactive, secure, and gas-efficient, leveraging the ERC20 token standard for transactions. Below is an overview of its functionality:

## Key Features

### Quiz Creation:

A user (creator) can launch a quiz by specifying:
A hashed answer (stored securely on-chain).
An end time for the quiz (up to 90 days).
The price to participate in the quiz.
Metadata (e.g., question, description, or image) stored in a URI.
An event Launch is emitted with the quiz details.

### Quiz Participation:

Participants can guess the answer by submitting a response and paying the required price in Ether.
If the hash of the submitted answer matches the stored hash:
The participant wins and receives the pledged amount.
A GuessWin event is emitted.
If the answer is incorrect:
A GuessLose event is emitted.

### Payouts:

The creator can claim the total pledged Ether if no one has answered correctly by the end of the quiz.
Funds are securely transferred using an ERC20 token.

### Quiz Storage and Retrieval:

All quizzes are stored in a mapping for efficient lookup.
Users can retrieve all quiz details using the viewAllQuizes function.
Roles

### Quiz Creator:

Initiates the quiz with predefined rules.
Can claim funds if no winner is declared.

### Participant:

Pays a fee to attempt the quiz.
Wins the pledged amount if the answer is correct.


### Security Measures

Hash-based answer validation ensures the quiz's integrity and prevents cheating.
Timelocks and restrictions prevent unauthorized access to quiz funds.
The contract ensures that only the creator or rightful winner can claim funds.


