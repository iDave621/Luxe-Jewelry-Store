import { render, screen } from '@testing-library/react';
import App from '../App';
import userEvent from '@testing-library/user-event';

// Mock the fetch API
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve([])
  })
);

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn()
};
Object.defineProperty(window, 'localStorage', { value: localStorageMock });

describe('Navigation Component', () => {
  beforeEach(() => {
    // Reset mocks
    fetch.mockClear();
    localStorageMock.getItem.mockClear();
    localStorageMock.setItem.mockClear();
    localStorageMock.removeItem.mockClear();
  });

  test('renders main navigation elements', async () => {
    render(<App />);
    
    // Check for brand name
    expect(screen.getByText(/Luxe Jewelry/i)).toBeInTheDocument();
    
    // Check for navigation links
    expect(screen.getByRole('button', { name: /home/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /products/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /cart/i })).toBeInTheDocument();
  });

  test('renders login button when user is not logged in', () => {
    localStorageMock.getItem.mockReturnValue(null);
    render(<App />);
    
    expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument();
  });

  test('clicking login button opens auth modal', async () => {
    const user = userEvent.setup();
    render(<App />);
    
    // Click login button
    await user.click(screen.getByRole('button', { name: /login/i }));
    
    // Check that modal appears
    expect(screen.getByText('Login')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Email')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Password')).toBeInTheDocument();
  });
});
