import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { PocketbaseService } from '../services/pocketbase.service';

export const AdminGuard: CanActivateFn = (route, state) => {
  const pbService = inject(PocketbaseService);
  const router = inject(Router);

  // Check if user is authenticated and is admin
  // This will need to be enhanced with proper admin checking logic
  if (pbService.isAuthenticated) {
    const user = pbService.currentUser;
    // For now, just check if user exists - implement proper admin check
    if (user) {
      return true;
    }
  }

  router.navigate(['/dashboard']);
  return false;
};