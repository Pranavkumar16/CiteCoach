import type {Book} from '../domain/models';

export const sampleBooks: Book[] = [
  { id: 'ml', title: 'Introduction to Machine Learning', meta: 'Sample book · 240 pages', sample: true },
  { id: 'ds', title: 'Data Science Foundations', meta: 'Sample book · 128 pages', sample: true },
];
export const questions = [
  { q: 'Which task uses labelled training data?', options: ['Supervised learning', 'Clustering', 'Random guessing', 'Data compression'], answer: 0,
    explanation: 'Supervised learning learns a mapping from examples that include both inputs and target labels.', page: 12 },
  { q: 'Which is a classification task?', options: ['Predicting house prices', 'Detecting spam emails', 'Grouping similar customers', 'Compressing an image'], answer: 1,
    explanation: 'Classification predicts a discrete category, such as spam or not spam.', page: 14 },
  { q: 'What does a regression model predict?', options: ['Only text labels', 'Unlabelled groups', 'A continuous value', 'The number of chapters'], answer: 2,
    explanation: 'Regression predicts a numeric value, such as a price or temperature.', page: 15 },
];
export const flashcards = [
  { q: 'What is supervised learning?', a: 'Learning from labelled examples to predict a target for new inputs.', page: 12 },
  { q: 'How does classification differ from regression?', a: 'Classification predicts a category. Regression predicts a continuous value.', page: 14 },
  { q: 'Why use a test set?', a: 'To evaluate how well the model generalizes to unseen examples.', page: 18 },
];
