import { render, screen } from '@testing-library/react';
import App from '../App';
import userEvent from '@testing-library/user-event';

// Simple mock for fetch API
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve([])
  })
);

// Simple mock for localStorage
Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: jest.fn(() => null),
    setItem: jest.fn(),
  }
});

test('clicking products button shows products page', async () => {
  render(<App />);
  
  // Set up user events
  const user = userEvent.setup();
  
  // Find and click products button
  const productsButton = screen.getByRole('button', { name: /products/i });
  await user.click(productsButton);
  
  // Check if products page heading appears
  const productsHeading = screen.getByText('Our Collection');
  expect(productsHeading).toBeInTheDocument();
});

test('clicking cart button shows shopping cart', async () => {
  render(<App />);
  
  // Set up user events
  const user = userEvent.setup();
  
  // Find and click cart button
  const cartButton = screen.getByRole('button', { name: /cart/i });
  await user.click(cartButton);
  
  // Check if cart heading appears
  const cartHeading = screen.getByText('Shopping Cart');
  expect(cartHeading).toBeInTheDocument();
});

test('login button opens authentication modal', async () => {
  render(<App />);
  
  // Set up user events
  const user = userEvent.setup();
  
  // Find and click login button
  const loginButton = screen.getByRole('button', { name: /login/i });
  await user.click(loginButton);
  
  // Check if login modal appears with form fields
  const emailInput = screen.getByPlaceholderText('Email');
  const passwordInput = screen.getByPlaceholderText('Password');
  
  expect(emailInput).toBeInTheDocument();
  expect(passwordInput).toBeInTheDocument();
});
