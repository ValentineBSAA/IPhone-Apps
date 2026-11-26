# Last Seen coding-agent instructions

Read DEVELOPMENT_HANDOFF.md and BUILD32_EXECUTION_PLAN.md. Keep story details private in creator-facing updates. Work on feature/last-seen-build27-noras-world. Do not start the native IPA build until the creator authorizes it.

## ElevenLabs project onboarding (creator requested)
From this LastSeen directory, run the official command:

    npx -y @elevenlabs/cli@latest onboard init

Follow the CLI's printed onboarding instructions, including the user's sign-in/consent step if required. Do not claim login succeeded until verified. Never display, commit, transmit to chat, or embed an API key in an IPA. Keep credentials in an ignored local env file or a protected Actions secret. Inspect git diff and staged files before committing any generated nonsecret configuration. If npm/network or browser authentication is unavailable, report the exact blocker. Do not run interactive onboarding in unattended CI.

The existing one-take voice-production workflow is separate: CLI onboarding does not automatically populate GitHub repository Actions secrets. See VoiceAssets/README.md. The authorized target is ten clips, one take each, estimated 1,001 credits, maximum planned budget 1,100; no automatic regeneration or retries. Candidate files require voice and rights approval before runtime import. No new paid generation merely to test authentication.
