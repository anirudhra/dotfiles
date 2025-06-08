# ssh keys

Sometimes the keys are not registered properly with the ssh-agent and will keep asking for passphrase. To solve that issue, after the keys have been generated, run:

```
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa
```
