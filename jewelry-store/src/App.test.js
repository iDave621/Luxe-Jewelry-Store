import { render, screen } from '@testing-library/react';
import App from './App';

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

test('renders Luxe Jewelry heading', () => {
  render(<App />);
  const headingElement = screen.getByText(/Luxe Jewelry/i);
  expect(headingElement).toBeInTheDocument();
});

test('renders navigation buttons', () => {
  render(<App />);
  const homeButton = screen.getByRole('button', { name: /home/i });
  const productsButton = screen.getByRole('button', { name: /products/i });
  const cartButton = screen.getByRole('button', { name: /cart/i });
  
  expect(homeButton).toBeInTheDocument();
  expect(productsButton).toBeInTheDocument();
  expect(cartButton).toBeInTheDocument();
});

test('renders footer with copyright', () => {
  render(<App />);
  const footerText = screen.getByText(/2024 Luxe Jewelry/i);
  expect(footerText).toBeInTheDocument();
});
