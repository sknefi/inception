# Docker Notes

This README is a compact, practical set of Docker notes focused on the *must-know* basics—especially the parts we discussed: build vs run, mounts (bind/volume/tmpfs), Node.js `node_modules` tricks, and debugging. 

TL;DR my (fkarika) notes, when learning docker (many examples are from official Docker dekstop application tutorial)

---

## 1. Core Concepts: Image vs Container vs Volume

- **Dockerfile**: a text recipe describing how to build an image (instructions like `FROM`, `RUN`, `COPY`, `CMD`).
- **Image**: an immutable template built from a Dockerfile. Commonly treated as a **build/deploy artifact**.
- **Container**: a running instance of an image (image layers + a writable container layer).
- **Volume**: persistent storage **outside** the container lifecycle (stored on the host, managed by Docker).

Key idea:
- Deleting a container deletes its writable layer.
- Volumes can outlive containers and keep data.

![Dockerfile](https://miro.medium.com/v2/resize:fit:1400/format:webp/0*g_MIQx7o6MSIzNiY.png)
---

## 2. Build-Time vs Run-Time: `RUN` vs `CMD`

- **`RUN ...`** executes during **`docker build`** (creates a new image layer).
- **`CMD ...`** executes when the container **starts** (`docker run` / `docker compose up`).
- Containers run as long as the **main process (PID 1)** is running. If it exits, the container stops.
- [Docker file reference ](https://docs.docker.com/reference/dockerfile/)

Typical flow:
- Build: `docker build -t my-app:1.0 .`
- Run: `docker run my-app:1.0`

---

## 3. `WORKDIR` (and Paths)

`WORKDIR /usr/src/app` is like:

- `mkdir -p /usr/src/app` (if missing)
- `cd /usr/src/app`

After this, relative paths in `RUN`, `COPY`, etc. resolve from that directory.

---

## 4. Runtime Mounts (Must-Know) + Table

A **mount** means: “make a container path point to some external storage.”

### Mount Types Table (Runtime)

| Type | Compose / CLI example | Stored where | Persistent | Best for | Notes / gotchas |
|---|---|---|---|---|---|
| **Bind mount** | `./app:/usr/src/app` | Your chosen host path | ✅ | Dev (hot reload), local configs/logs | Live link to host files. Overrides image content at that path. |
| **Named volume** | `mongo_data:/data/db` | Host disk, Docker-managed location | ✅ | Databases, persistent app data | Docker chooses the physical location. Easy to reuse and back up. |
| **Anonymous volume** | `/usr/src/app/node_modules` | Host disk, Docker-managed location | ✅ (until removed) | “Keep data off the host repo”, Node `node_modules` trick | Same as a volume, just without a human-friendly name. |
| **tmpfs** | `tmpfs: - /cache` / `--tmpfs /cache` | RAM | ❌ | Cache, temp files, sensitive scratch data | Fast, but ephemeral. Can consume host RAM. |


### Golden rules
- Want **live code edits**? Use **bind mount**.
- Want **persistent data**? Use a **named volume**.
- Want **fast ephemeral scratch**? Use **tmpfs**.

![](https://miro.medium.com/v2/resize:fit:1400/1*EjM5SWI8iDeQ7PgwD5BAaw.png)

---

## 5. Bind Mount vs `COPY`

- **`COPY`** (Dockerfile): copies files into the **image** at build time (a snapshot).
- **Bind mount** (Compose / `docker run`): connects a host path into the **running container** (live).

Important:
- A bind mount **overrides** whatever was inside the image at that container path.

---

## 6. Volumes vs Mounts (Vocabulary)

- **Mount** = the *act* of attaching storage to a container path.
- **Volume** = one storage type that can be mounted (Docker-managed).

So: *Every volume is mounted, but not every mount is a volume* (bind and tmpfs are mounts too).

---

## 7. Why `/usr/src/app/node_modules` as an Anonymous Volume (Node.js Dev Pattern)

Common Node.js dev pattern:

```yaml
volumes:
  - ./app:/usr/src/app
  - /usr/src/app/node_modules
```

Why it matters:
- `./app:/usr/src/app` brings code from the host (great for dev).
- Without the second mount, `node_modules` would end up on the host (or be OS-incompatible).
- The second mount “shields” the `node_modules` subfolder so dependencies live in Docker storage (Linux-compatible).

The anonymous volume is just “a Docker-managed storage slot.”  
`npm ci` / `npm install` writes dependencies into that mount.

**Named alternative (more explicit):**
```yaml
volumes:
  - ./app:/usr/src/app
  - node_modules_cache:/usr/src/app/node_modules

volumes:
  node_modules_cache:
```

---

## 8. Networking in Docker Compose (Service Discovery)

- Services in the same Compose project share a network by default.
- Containers can reach each other via **service name** DNS.
  - Example: app connects to Mongo using hostname `todo-database` (not `localhost`).
- Publishing ports (`ports:`) is only needed for *host ↔ container* access.

Note: `links:` is largely legacy; DNS works without it in modern Compose setups.

---

## 9. Ports: `EXPOSE` vs `ports`

- **`EXPOSE 3001`** (Dockerfile): documentation/metadata (does *not* publish).
- **`ports: - 3001:3001`** (Compose): publishes container port to the host.

---

## 10. Users & Permissions: `USER`, `chown`, and Common “EACCES” Issues

- `USER node` switches the default user inside the container from root to `node`.
- `chown` changes file ownership (who owns files).
- `chmod` changes permissions (what can be done: read/write/execute).

Common dev pain:
- A bind mount points to host files with host ownership/permissions.
- A non-root container user may not be able to write into that bind mount → `EACCES`.

Typical mitigations:
- Keep write-heavy folders like `node_modules` in a **volume** (not a bind mount).
- Ensure ownership is correct inside the image (`chown -R node:node /usr/src/app`) when you are not bind-mounting.
- Advanced: align UID/GID between host and container.

---

## 11. BuildKit Mounts in Dockerfile (`RUN --mount=...`)

When using BuildKit, you can mount things **during a build step** (only for that `RUN` line):

- `type=bind`: temporarily mount files (e.g., `package.json`, `package-lock.json`) so the dependency layer rebuilds only when those change.
- `type=cache`: keep package manager caches between builds (`/root/.npm`, pip cache, etc.).
- `type=secret`: provide tokens during build without baking them into the image.
- `type=ssh`: allow `git clone` from private repos during build without copying SSH keys into the image.

This is different from runtime mounts: build mounts exist only during the build step.

---

## 12. Caching and Layer Strategy (Why builds get faster / slower)

- Docker caches layers. If inputs don’t change, a step can be reused.
- For Node projects, you typically want dependencies in a layer that changes only when `package*.json` changes.

Common strategy:
1) Copy only `package*.json`
2) Install deps
3) Copy the rest of the app

Or the BuildKit approach you used: bind-mount `package*.json` during `RUN npm ci`.

---

## 13. Debugging Checklist (Logs / Exec / Inspect)

Most useful commands:

- View logs:
  ```bash
  docker compose logs -f todo-app
  ```

- Enter container shell:
  ```bash
  docker compose exec todo-app sh
  # or:
  docker exec -it <container_id> sh
  ```

- Inspect mounts and port mappings:
  ```bash
  docker inspect <container_id>
  docker port <container_id>
  ```

If a container “won’t start”, it usually means the main process exited:
- missing dependency (e.g., `nodemon` not installed)
- wrong env vars
- permission errors
- app crash

---

## 14. Resetting State (Volumes and “Stale Data”)

Volumes can outlive containers and images, so you can end up with “old” state.

Reset everything for a Compose project (including volumes):

```bash
docker compose down -v
docker compose up --build
```

- `down -v` removes containers **and** volumes for that project.
- `up --build` rebuilds images and starts services.

---

## 15. `.dockerignore` (Must-have in Real Projects)

Without `.dockerignore`, your build context can include huge/unwanted files.

Typical `.dockerignore` for Node:

```text
node_modules
.git
dist
build
npm-debug.log
Dockerfile
docker-compose.yml
```

Adjust to your project.

---
## 17. Most Common Docker Commands (Cheat Sheet)

### 17.1 Building images
- **`docker build -t my-app:1.0.0 .`**
- `docker build --no-cache -t my-app:1.0.0 .` (build without cache)
- `docker pull <image>` (e.g., `mongo:6`)

### 17.2 Image management
- **`docker images`**
- **`docker rmi <image_id>`**
- **`docker tag <image_id> my-app:latest`**
- `docker push my-app:<tag>` (if using a registry)
- `docker image prune` (remove unused images)

### 17.3 Running containers
- **`docker run --rm <image>`**
- **`docker run --rm -it <image> sh`**
- `docker run -d --name myapp -p 3001:3001 <image>` (detached, named, port published)
- `docker run --env KEY=value <image>`
- `docker run -v <host_path>:<container_path> <image>` (bind mount)
- `docker run -v <volume_name>:<container_path> <image>` (named volume)

### 17.4 Listing and inspecting containers
- **`docker ps`**
- **`docker ps -a`**
- **`docker logs <container_id>`**
- `docker logs -f <container_id>` (follow)
- **`docker inspect <container_id>` (everything: mounts, env, networking, etc.)**
- `docker port <container_id>` (published ports)
- `docker stats` (live CPU/RAM)

### 17.5 Exec / debugging inside containers
- **`docker exec -it <container_id> sh`**
- `docker exec -it <container_id> bash` (if available)

### 17.6 Stop/start/remove containers
- **`docker stop <container_id>`**
- **`docker start <container_id>`**
- **`docker restart <container_id>`**
- **`docker rm <container_id>`**
- `docker container prune` (remove all stopped containers)

### 17.7 Volumes
- **`docker volume ls`**
- **`docker volume inspect <volume_name>`**
- **`docker volume create <name>`**
- **`docker volume rm <name>`**
- `docker volume prune` (careful: removes unused volumes)

### 17.8 Docker Compose
- **`docker compose up --build`**
- **`docker compose up -d`**
- **`docker compose down`**
- `docker compose down -v` (reset state incl. volumes)
- `docker compose ps`
- `docker compose logs -f`
- `docker compose exec <service> sh`

### 17.9 Networks (basic)
- **`docker network ls`**
- `docker network inspect <network>`
- `docker network prune`


---

## Bonus: Image as an Artifact (CI/CD)
A Docker image is commonly treated as a deployable artifact:
build → tag → push to registry → deploy by pulling the same image.
For immutability, teams often deploy using an image **digest** instead of a mutable tag.

