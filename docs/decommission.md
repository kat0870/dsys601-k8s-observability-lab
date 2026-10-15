# Decommission and whole-class reset (Task 13)

`teardown-reset.md` covers resetting one lab between cohorts. This document covers
the other two cases: resetting a whole class of student VMs, and fully retiring the lab.

## 1. Resetting a whole class

Each student has their own VM on a lab PC, copied from `P:\Clones`. There are three ways
to bring every VM back to a clean lab:

| Option | How | Time per VM | Needs internet | Best for |
|---|---|---|---|---|
| A. Reset script | Student runs `./reset-lab.sh`, types `RESET`, checks `LAB READY` | About 2 min (measured 2 min 7 s, 14 Oct 2026) | Only if images are missing | Start of a lab session |
| B. VMware snapshot | Take a snapshot called `lab-ready` after the first `LAB READY`; revert to it with VM > Snapshot > Revert | Under 1 min | No | Fixing one broken VM quickly |
| C. Golden image | Build one VM with the tools installed, images downloaded and `LAB READY`; put it in `P:\Clones` as the base students copy | Copy time only | No | Between cohorts |

**Recommendation:** use **C between cohorts** and **A at the start of each session**.
A fresh install downloads several GB per VM. A whole class doing that at once on the
lab network is the slowest part, and the golden image removes it. The reset script
reuses the downloaded images, so it stays fast.

To build the golden image:

1. Set up one VM with `docs/handover.md`, ending with `./reset-lab.sh` and `LAB READY`.
2. Run `./cluster/teardown-cluster.sh` so the image does not contain a running cluster.
   The downloaded images stay in Docker, so students' first reset is fast.
3. Delete `.env` (each tutor or student sets their own password with `cp .env.example .env`).
4. Shut the VM down and copy it to `P:\Clones` as the new base.

This has not yet been tested with a full class. It feeds into Task 14.

## 2. Decommission (fully retiring the lab)

Use this when the lab will no longer be taught on these machines.

**If the whole VM is being deleted, only steps 1, 2 and 8 are needed.**

### Steps

1. **Agree with the teaching team** that the lab is being retired and nobody needs it.
2. **Archive the repo.** Tag the final version and archive it on GitHub
   (Settings > Archive this repository), so it stays readable for later courses:
   ```bash
   git tag -a v-final -m "DSYS601 observability lab: final version before retirement"
   git push --tags
   ```
3. **Delete the cluster:**
   ```bash
   ./cluster/teardown-cluster.sh
   ```
4. **Delete Docker leftovers** (Kind network, images, volumes):
   ```bash
   docker network rm kind
   docker system prune -a --volumes
   ```
5. **Remove the lab settings and tools:**
   ```bash
   sudo rm -f /etc/systemd/system/user@.service.d/delegate.conf
   sudo systemctl daemon-reload
   sudo rm -f /usr/local/bin/kind /usr/local/bin/kubectl /usr/local/bin/helm
      sudo rm -f /etc/sysctl.d/99-kind.conf
   sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
   sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc
   ```
6. **Remove the Docker disk, in this order:**
   1. Delete the Docker disk line from `/etc/fstab` **first** (`sudo nano /etc/fstab`).
      If the disk is removed while that line is still there, Ubuntu boots into
      emergency mode. This happened on the dev VM on 8 Oct 2026.
   2. Unmount it: `sudo umount /var/lib/docker`
   3. Shut down the VM and remove the disk in VMware (VM > Settings > Hard Disk > Remove).
7. **Remove secrets:** delete the repo folder, including `.env`, and `~/.kube/config`.
8. **Delete the VMs** (student copies on `D:` and the golden image in `P:\Clones`)
   if they are no longer needed.

### Check it is gone

```bash
kind get clusters      # command not found
docker ps              # command not found
lsblk                  # no 40 GB Docker disk
```

### Decommission record

| Date | By | Machines | Final repo version | Result |
|---|---|---|---|---|
| | | | | |
