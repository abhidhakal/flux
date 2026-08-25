import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../auth/auth_bloc.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void showEditProfileDialog(BuildContext context, User user) {
  final authService = AuthService();
  final isEmailUser = authService.isEmailPasswordUser;
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  final nameController = TextEditingController(text: user.displayName ?? '');
  final emailController = TextEditingController();
  final currentPwController = TextEditingController();
  final newPwController = TextEditingController();
  final confirmPwController = TextEditingController();

  final nameKey = GlobalKey<FormFieldState>();
  final emailKey = GlobalKey<FormFieldState>();
  final pwKey = GlobalKey<FormState>();

  AppBottomSheet.show(
    context,
    radius: 28,
    isScrollControlled: true,
    padding: EdgeInsets.zero,
    builder: (sheetCtx) {
      bool savingName = false;
      bool savingEmail = false;
      bool savingPw = false;
      bool showCurrentPw = false;
      bool showNewPw = false;
      bool showConfirmPw = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          LucideIcons.userRoundPen,
                          color: AppColors.primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Profile',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(
                              'Update your account details securely',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Display Name ────────────────────────────
                  Text('Display Name',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          key: nameKey,
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          hintText: 'Your name',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter a name'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _saveButton(
                        loading: savingName,
                        onTap: () async {
                          if (nameKey.currentState?.validate() != true) {
                            return;
                          }
                          setState(() => savingName = true);
                          try {
                            await authService.updateProfile(
                              userId: user.id,
                              displayName: nameController.text.trim(),
                            );
                            if (context.mounted) {
                              context
                                  .read<AuthBloc>()
                                  .add(AuthCheckRequested());
                              Navigator.pop(sheetCtx);
                              AppSnackbar.showSuccess(
                                context,
                                message: 'Name updated',
                              );
                            }
                          } catch (e) {
                            setState(() => savingName = false);
                            if (context.mounted) {
                              AppSnackbar.showError(
                                context,
                                message:
                                    e.toString().replaceAll('Exception: ', ''),
                              );
                            }
                          }
                        },
                        cs: cs,
                      ),
                    ],
                  ),

                  if (isEmailUser) ...[
                    const SizedBox(height: 28),
                    Divider(color: cs.outline.withValues(alpha: 0.15)),
                    const SizedBox(height: 20),

                    // ── Email ──────────────────────────────────
                    Text('Change Email',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'A verification link will be sent to the new address.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            key: emailKey,
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            hintText: 'New email address',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter an email';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        _saveButton(
                          loading: savingEmail,
                          onTap: () async {
                            if (emailKey.currentState?.validate() != true) {
                              return;
                            }
                            setState(() => savingEmail = true);
                            try {
                              await authService.updateEmail(
                                userId: user.id,
                                newEmail: emailController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(sheetCtx);
                                AppSnackbar.showSuccess(
                                  context,
                                  message:
                                      'Verification email sent — check your inbox',
                                );
                              }
                            } catch (e) {
                              setState(() => savingEmail = false);
                              if (context.mounted) {
                                AppSnackbar.showError(
                                  context,
                                  message: e
                                      .toString()
                                      .replaceAll('Exception: ', ''),
                                );
                              }
                            }
                          },
                          cs: cs,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    Divider(color: cs.outline.withValues(alpha: 0.15)),
                    const SizedBox(height: 20),

                    // ── Password ───────────────────────────────
                    Text('Change Password',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: savingPw
                            ? null
                            : () async {
                                setState(() => savingPw = true);
                                try {
                                  await authService.resetPassword(user.email);
                                  if (context.mounted) {
                                    Navigator.pop(sheetCtx);
                                    AppSnackbar.showSuccess(
                                      context,
                                      message:
                                          'Password reset link sent to ${user.email}',
                                    );
                                  }
                                } catch (e) {
                                  setState(() => savingPw = false);
                                  if (context.mounted) {
                                    AppSnackbar.showError(
                                      context,
                                      message: 'Failed to send reset email',
                                    );
                                  }
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.formFieldRadius)),
                        ),
                        icon: savingPw
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.mail, size: 18),
                        label: const Text('Send password reset email',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: cs.outline.withValues(alpha: 0.2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or change manually',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                        Expanded(
                            child: Divider(
                                color: cs.outline.withValues(alpha: 0.2))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: pwKey,
                      child: Column(
                        children: [
                          AppTextField(
                            controller: currentPwController,
                            obscureText: !showCurrentPw,
                            hintText: 'Current password',
                            suffixIcon: _eyeToggle(
                              showCurrentPw,
                              cs,
                              () => setState(
                                  () => showCurrentPw = !showCurrentPw),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter current password'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: newPwController,
                            obscureText: !showNewPw,
                            hintText: 'New password',
                            suffixIcon: _eyeToggle(
                              showNewPw,
                              cs,
                              () => setState(() => showNewPw = !showNewPw),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter new password';
                              }
                              if (v.length < 6) {
                                return 'At least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: confirmPwController,
                            obscureText: !showConfirmPw,
                            hintText: 'Confirm new password',
                            suffixIcon: _eyeToggle(
                              showConfirmPw,
                              cs,
                              () => setState(
                                  () => showConfirmPw = !showConfirmPw),
                            ),
                            validator: (v) => v != newPwController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: savingPw
                                  ? null
                                  : () async {
                                      if (!pwKey.currentState!.validate()) {
                                        return;
                                      }
                                      setState(() => savingPw = true);
                                      try {
                                        await authService.updatePassword(
                                          currentPassword:
                                              currentPwController.text,
                                          newPassword: newPwController.text,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(sheetCtx);
                                          AppSnackbar.showSuccess(context,
                                              message: 'Password updated');
                                        }
                                      } catch (e) {
                                        setState(() => savingPw = false);
                                        if (context.mounted) {
                                          final msg = e
                                              .toString()
                                              .replaceAll('Exception: ', '');
                                          AppSnackbar.showError(context,
                                              message: msg);
                                        }
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.formFieldRadius)),
                              ),
                              child: savingPw
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Update Password',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    nameController.dispose();
    emailController.dispose();
    currentPwController.dispose();
    newPwController.dispose();
    confirmPwController.dispose();
  });
}

Widget _saveButton(
    {required bool loading,
    required VoidCallback onTap,
    required ColorScheme cs}) {
  return SizedBox(
    height: 50,
    child: FilledButton(
      onPressed: loading ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
    ),
  );
}

Widget _eyeToggle(bool visible, ColorScheme cs, VoidCallback onTap) {
  return IconButton(
    icon: Icon(visible ? LucideIcons.eyeOff : LucideIcons.eye,
        size: 20, color: cs.onSurfaceVariant),
    onPressed: onTap,
  );
}
