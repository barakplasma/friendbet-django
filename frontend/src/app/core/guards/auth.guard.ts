import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { PocketbaseService } from '../services/pocketbase.service';

export const AuthGuard: CanActivateFn = (route, state) => {
  const pbService = inject(PocketbaseService);
  const router = inject(Router);

  if (pbService.isAuthenticated) {
    return true;
  }

  router.navigate(['/login'], { queryParams: { returnUrl: state.url } });
  return false;
};