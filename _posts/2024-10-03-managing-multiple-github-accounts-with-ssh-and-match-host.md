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
The best way to handle multiple GitHub accounts is to use SSH keys and configure your SSH client to automatically use the correct key based on the repository you’re accessing.

## How to Set It Up

1. **Generate SSH Key Pairs for Each Account**
   If you haven't done so already, you'll need to generate separate SSH key pairs for each GitHub account. Here’s how you can create a new SSH key:

   ```bash
   cd ~/.ssh 
   ssh-keygen
   ```

   - When prompted, you can specify the name of your file, for example, `gambitier_private_key` for your personal account or `gambitier-work_private_key` for your work account. This way, you will have separate keys for each account.
   - After generating the key, add the public key to your GitHub account by following the instructions in [GitHub's documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

   Here's how your `.ssh` directory might look after creating your keys:

   ```bash
   ls ~/.ssh 
   
   config
   gambitier_private_key
   gambitier_private_key.pub
   gambitier-work_private_key
   gambitier-work_private_key.pub
   known_hosts
   ```

2. **Edit/Create the SSH Config File (`~/.ssh/config`)**
   Open or create the SSH config file in your home directory and add the following configuration:

   ```
   # Default GitHub account for personal projects
   Host github.com
       HostName github.com
       IdentityFile ~/.ssh/gambitier_private_key
       IdentitiesOnly yes

   # Work-related GitHub account
   Match host github.com exec "git config --get remote.origin.url | grep -q 'work-organization'"
       IdentityFile ~/.ssh/gambitier-work_private_key
       IdentitiesOnly yes
   ```

   > **NOTE:** Using the default hostname (`github.com`) for personal projects simplifies your workflow.

3. **Add SSH Private Keys to Your SSH Agent**
   Use the following commands to add your private keys to the SSH agent:

   ```bash
   ssh-add ~/.ssh/gambitier_private_key
   ssh-add ~/.ssh/gambitier-work_private_key
   ```

4. **Test Your Connection**
   To ensure that your SSH configuration is working, run the following command for your personal account:

   ```bash
   ssh -T git@github.com
   ```

   You should see a message like:

   ```plaintext
   Hi gambitier! You've successfully authenticated, but GitHub does not provide shell access.
   ```

   Now cd to your work repo, test your work account:

   ```bash
   cd work-repo
   ssh -T git@github.com
   ```

   If configured correctly for your work account, you should see:

   ```
   Hi GambitierWork! You've successfully authenticated, but GitHub does not provide shell access.
   ```

5. **Working with Repositories**
   Now that everything is set up, remember the following conventions when working with your repositories:

   - To clone a repository for your work account, use:
     ```bash
     GIT_SSH_COMMAND="ssh -i ~/.ssh/gambitier-work_private_key" git clone git@github.com:work-organization/project.git /path/to/project
     cd /path/to/project
     git config user.email "gambitier-work@example.com"
     git config user.name  "GambitierWork"
     ```

   - If you already have the repository set up, change the `origin` URL to match your work account:
     ```bash
     cd /path/to/project
     git remote set-url origin git@github.com:work-organization/project.git
     ```
     
     and then set git config as usual
     ```bash
     git config user.email "gambitier-work@example.com"
     git config user.name  "GambitierWork"
     ```

   - For new repositories:
     ```bash
     cd /path/to/new-project
     git init
     git remote add origin git@github.com:work-organization/project.git
     git config user.email "gambitier-work@example.com"
     git config user.name  "GambitierWork"
     git add .
     git commit -m "Initial commit"
     git push -u origin master
     ```

## Advantages of Using `Match` Host Syntax
The `Match` directive in your SSH configuration provides several advantages:

- **Dynamic Key Selection:** It allows you to specify different identity files based on the repository being accessed, which automates the SSH key selection process.
- **Simplifies Workflow:** You can use the same host (`github.com`) for all your accounts without needing custom aliases, making your Git commands cleaner and easier to remember.
- **Flexibility:** You can add as many conditions as needed for different accounts or organizations without cluttering your SSH configuration with numerous host entries.
- **Reduced Errors:** With the automatic selection of SSH keys based on repository URLs, you minimize the chances of accidentally using the wrong credentials.

## Conclusion
By following these steps, you can seamlessly manage multiple GitHub accounts on the same machine without needing to input your password repeatedly. This setup will enhance your productivity and make your development workflow much smoother.

## References
- [Using multiple github accounts with ssh keys](https://gist.github.com/oanhnn/80a89405ab9023894df7)
- [Parse "Match Host" from ssh config](https://github.com/Microsoft/vscode-remote-release/issues/37)
