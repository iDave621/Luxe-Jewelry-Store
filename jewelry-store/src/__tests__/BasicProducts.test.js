import { render, screen } from '@testing-library/react';
import App from '../App';

// Simple mock data for products
const mockProducts = [
  {
    id: 1,
    name: 'Diamond Ring',
    description: 'Beautiful diamond ring',
    price: 999.99,
    image: 'https://example.com/ring.jpg'
  },
  {
    id: 2,
    name: 'Gold Earrings',
    description: 'Elegant gold earrings',
    price: 499.99,
    image: 'https://example.com/earrings.jpg'
  }
];

// Mock fetch API to return our products
global.fetch = jest.fn((url) => {
  return Promise.resolve({
    ok: true,
    json: () => Promise.resolve(url.includes('/products') ? mockProducts : [])
  });
});

// Simple mock for localStorage
Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: jest.fn(() => 'test-session'),
    setItem: jest.fn(),
  }
});

test('renders product names when products are loaded', async () => {
  render(<App />);
  
  // Look for product names
  const ringProduct = await screen.findByText('Diamond Ring');
  const earringsProduct = await screen.findByText('Gold Earrings');
  
  expect(ringProduct).toBeInTheDocument();
  expect(earringsProduct).toBeInTheDocument();
});

test('renders product prices correctly', async () => {
  render(<App />);
  
  // Look for product prices
  const ringPrice = await screen.findByText('$999.99');
  const earringsPrice = await screen.findByText('$499.99');
  
  expect(ringPrice).toBeInTheDocument();
  expect(earringsPrice).toBeInTheDocument();
});

test('renders add to cart buttons for products', async () => {
  render(<App />);
  
  // Look for "Add to Cart" buttons
  const addToCartButtons = await screen.findAllByText('Add to Cart');
  
  // Should have at least two buttons (one for each product)
  expect(addToCartButtons.length).toBeGreaterThanOrEqual(2);
});
