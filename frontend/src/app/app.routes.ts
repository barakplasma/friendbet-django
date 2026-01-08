import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/login',
    pathMatch: 'full'
  },
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'auth/callback',
    loadComponent: () => import('./features/auth/auth-callback.component').then(m => m.AuthCallbackComponent)
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent),
    canActivate: () => import('./core/guards/auth.guard').then(m => m.AuthGuard)
  },
  {
    path: 'groups',
    loadChildren: () => import('./features/groups/groups.routes').then(m => m.GROUPS_ROUTES),
    canActivate: () => import('./core/guards/auth.guard').then(m => m.AuthGuard)
  },
  {
    path: 'markets',
    loadChildren: () => import('./features/markets/markets.routes').then(m => m.MARKETS_ROUTES),
    canActivate: () => import('./core/guards/auth.guard').then(m => m.AuthGuard)
  },
  {
    path: 'leaderboard',
    loadComponent: () => import('./features/leaderboard/leaderboard.component').then(m => m.LeaderboardComponent),
    canActivate: () => import('./core/guards/auth.guard').then(m => m.AuthGuard)
  },
  {
    path: 'profile',
    loadComponent: () => import('./features/profile/profile.component').then(m => m.ProfileComponent),
    canActivate: () => import('./core/guards/auth.guard').then(m => m.AuthGuard)
  },
  {
    path: 'admin',
    loadChildren: () => import('./features/admin/admin.routes').then(m => m.ADMIN_ROUTES),
    canActivate: () => import('./core/guards/admin.guard').then(m => m.AdminGuard)
  }
];