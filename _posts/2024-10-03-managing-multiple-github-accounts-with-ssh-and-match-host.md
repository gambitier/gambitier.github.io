---
title: Managing multiple GitHub accounts with SSH & `Match host` syntax
date: 2024-10-03
categories: [Software Development]
tags: [SSH, GitHub, Git]
author: gambitier
pin: false
mermaid: false
---

As a developer, you might find yourself juggling multiple GitHub accounts for different purposes — one for personal projects and another for work-related tasks. The challenge arises when you want to use both accounts on the same machine without constantly entering your password during `git push` or `git pull`.

## Solution
The best way to handle multiple GitHub accounts is to use SSH keys and configure your SSH client to automatically use the correct key based on the repository you're accessing.

## How to Set It Up

### 1. Generate SSH Key Pairs for Each Account
First, generate separate SSH key pairs for each GitHub account using the modern Ed25519 algorithm:

```bash
# For personal account
ssh-keygen -t ed25519 -C "your-personal-email@example.com" -f ~/.ssh/personal_key

# For work account
ssh-keygen -t ed25519 -C "your-work-email@example.com" -f ~/.ssh/work_key
```

{: .prompt-info }
> The `-t ed25519` flag specifies the use of the Ed25519 algorithm, which is more secure and efficient than older alternatives.

### 2. Clear SSH Key Cache
Before proceeding, clear any existing cached keys:

```bash
ssh-add -D
```

### 3. Edit/Create the SSH Config File
Create or edit your SSH config file. You can use either of these two approaches:

#### Approach 1: Using Host Aliases
```config
# Personal GitHub account
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/personal_key
    IdentitiesOnly yes

# Work GitHub account
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/work_key
    IdentitiesOnly yes
```

#### Approach 2: Using Match Host Syntax
```config
# Personal GitHub account (default)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/personal_key
    IdentitiesOnly yes

# Work GitHub account (matched by repository URL pattern)
Match host github.com exec "git config --get remote.origin.url | grep -q 'WorkOrgName'"
    IdentityFile ~/.ssh/work_key
    IdentitiesOnly yes
```

{: .prompt-info }
> The `Match host` approach automatically selects the correct key based on the repository URL pattern, eliminating the need for different host aliases. However, it requires your repositories to follow a consistent naming pattern (e.g., all work repositories under the same organization name).

### 4. Add SSH Keys to GitHub
For each account:
- Log into the respective GitHub account
- Go to Settings → SSH and GPG keys
- Click "New SSH key"
- Give it a descriptive title
- Copy the contents of the respective .pub file (`cat ~/.ssh/personal_key.pub` or `cat ~/.ssh/work_key.pub`)
- Paste and save

### 5. Verify Connections
Test each connection separately:

```bash
# Test personal account
ssh -i ~/.ssh/personal_key -T git@github.com

# Test work account
ssh -i ~/.ssh/work_key -T git@github.com
```

You should see messages like:
```plaintext
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

{: .prompt-warning }
> If you get an error or see the wrong username, verify that:
> - The key is added to the correct GitHub account
> - The key permissions are correct (600 for private key, 644 for public key)
> - The key is not added to multiple GitHub accounts

### 6. Working with Repositories

#### Using Host Aliases (Approach 1)
When using host aliases, you need to specify the correct host in your git commands:

**First-time Clone:**
```bash
# For personal repositories
git clone git@github.com-personal:username/repo-name.git

# For work repositories
git clone git@github.com-work:organization/repo-name.git
```

#### Using Match Host (Approach 2)
When using the `Match host` approach, there's an important caveat for first-time clones:

**First-time Clone:**
For the initial clone, you'll need to explicitly specify which SSH key to use since the repository's remote URL isn't available yet:
```bash
# For work repositories
GIT_SSH_COMMAND="ssh -i ~/.ssh/work_key" git clone git@github.com:organization/repo-name.git

# For personal repositories
git clone git@github.com:username/repo-name.git  # Uses default key
```

**After Clone:**
Once the repository is cloned, all subsequent git operations (pull, push, fetch, etc.) will automatically use the correct SSH key based on the `Match host` pattern matching against the repository's remote URL.

{: .prompt-warning }
> The need to specify the SSH key during clone is a limitation of the `Match host` approach, as the pattern matching relies on the repository's remote URL which is only available after cloning.

##### Key Selection Process:
1. When you run a git command, SSH checks the repository's remote URL
2. If the URL matches the pattern in your `Match host` rule (e.g., contains 'WorkOrgName'), it uses the work key
3. If no match is found, it falls back to the default (personal) key

##### Advantages of Match Host:
- Simpler URLs - no need to remember different host aliases
- Works with copy-pasted GitHub URLs without modification
- Automatically selects the correct key based on repository organization
- Better compatibility with third-party tools that expect standard GitHub URLs
- Works seamlessly with package managers and dependency tools:
  - `go mod tidy` for fetching private Go modules
  - Node.js `npm install` for private packages
  - Other tools that interact with Git repositories

For example, when running `go mod tidy` with private modules:
```bash
# In go.mod
module example.com/myproject

require (
    github.com/WorkOrgName/private-module v1.0.0  // Will use work SSH key
    github.com/username/personal-module v1.0.0    // Will use personal SSH key
)
```

The SSH key selection happens automatically based on the repository URL pattern.

##### Limitations:
{: .prompt-danger }
- Requires consistent repository organization naming for pattern matching
- All repositories from the same organization must use the same SSH key
- More complex to debug if pattern matching isn't working as expected

## Repository Configuration
Regardless of the approach used, you still need to configure your git user information for each repository:
```bash
# For personal repositories
git config user.email "your-personal-email@example.com"
git config user.name "Your Personal Name"

# For work repositories
git config user.email "your-work-email@example.com"
git config user.name "Your Work Name"
```

{: .prompt-tip }
> To automate this process in Visual Studio Code, you can use the [git-autoconfig](https://marketplace.visualstudio.com/items?itemName=shyykoserhiy.git-autoconfig) extension. This extension:
> - Prompts you to set local user.email and user.name for each Git project you open
> - Provides a convenient selector for previously used email and name pairs
> - Helps prevent accidental commits with wrong user information
> - Can be configured with a list of predefined configurations for quick selection

## Troubleshooting

If you encounter issues, try the following:

1. **Check Key Permissions:**
   ```bash
   chmod 600 ~/.ssh/personal_key ~/.ssh/work_key
   chmod 644 ~/.ssh/personal_key.pub ~/.ssh/work_key.pub
   ```

2. **Verify SSH Agent:**
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add -l
   ```

3. **Debug Connection:**
   ```bash
   ssh -v -T git@github.com
   ```

4. **Clear SSH Cache:**
   ```bash
   ssh-add -D  # Removes all cached keys
   ```

## Advantages of This Setup

- **Clear Separation:** Each account has its own dedicated SSH key and host alias
- **No Key Conflicts:** The `IdentitiesOnly yes` option prevents key confusion
- **Easy Switching:** Using host aliases or `Match host` approach makes it clear which account you're using
- **Secure:** Using Ed25519 keys provides modern security standards

## Conclusion
This setup allows you to manage multiple GitHub accounts securely and efficiently. By using different SSH keys and host aliases or `Match host` approach, you can maintain clear separation between accounts while enjoying a smooth workflow.

## References
- [GitHub's SSH key guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [About Ed25519 keys](https://medium.com/risan/upgrade-your-ssh-key-to-ed25519-c6e8d60d3c54)
- [Git config conditional includes](https://git-scm.com/docs/git-config#_conditional_includes)