document.addEventListener("turbo:load", function () {
  console.log("✅ castr_controller.js chargé");

  const selects = document.querySelectorAll("[data-castr-target='streams']");
  console.log("🎯 stream selects trouvés :", selects.length);

  let castrStreams = [];

  fetch("/admin/streams/get_streams")
    .then(res => res.json())
    .then(data => {
      if (data.success && Array.isArray(data.data?.docs)) {
        castrStreams = data.data.docs;

        selects.forEach((streamSelect) => {
          streamSelect.addEventListener("change", function () {
            const streamId = this.value;
            const card = this.closest("[data-controller~='castr']");
            const form = this.closest("form");
            const endpointSelect = form?.querySelector("[data-castr-target='endpoint']");
            const classSelect = form?.querySelector("[data-castr-target='classSelect']");
            const classId = classSelect?.value;
            const showId = card?.dataset.providerId; // 🔁 Corrigé ici

            if (!endpointSelect) return;
            endpointSelect.innerHTML = "<option>Chargement...</option>";

            const stream = castrStreams.find(s => s._id === streamId);
            if (!stream || !Array.isArray(stream.platforms)) {
              endpointSelect.innerHTML = "<option>Pas de plateformes disponibles</option>";
              return;
            }

            const options = stream.platforms.map(p => {
              const value = p._id;
              const label = p.name?.trim() || p.server || "???";
              return value ? `<option value="${value}">${label}</option>` : "";
            }).join("");

            endpointSelect.innerHTML = options || "<option>Aucune plateforme</option>";

            const monitoringBlock = card.querySelector(".monitoring");
            if (monitoringBlock && classId && showId) {
              updateMonitoringStatus(classId, showId, monitoringBlock);
            }
          });
        });

      } else {
        console.warn("⚠️ Erreur lors du chargement initial des streams Castr.");
      }
    })
    .catch(err => {
      console.error("❌ Erreur fetch initial:", err);
    });

  document.querySelectorAll("[data-action='castr#start'], [data-action='castr#stop']").forEach(button => {
    button.addEventListener("click", handleStartStopStream);
  });

  function handleStartStopStream() {
    const actionType = this.getAttribute("data-action").includes("start") ? "start" : "stop";

    const card = this.closest("[data-controller~='castr']") || document;
    const streamSelect = card.querySelector("[data-castr-target='streams']");
    const endpointSelect = card.querySelector("[data-castr-target='endpoint']");
    const classSelect = card.querySelector("[data-castr-target='classSelect']");

    const streamId = this.dataset.streamId || streamSelect?.value;
    const platformId = this.dataset.platformId || endpointSelect?.value;
    const classId = this.dataset.classId || classSelect?.value;
    const showId = this.dataset.showId || card.dataset.providerId; // 🔁 Corrigé ici

    const apiKey = document.querySelector("meta[name='castr-api-key']")?.content;

    if (!streamId || !platformId || !classId || !apiKey || !showId) {
      console.warn({ streamId, platformId, classId, showId, apiKey });
      alert("⚠️ Veuillez vérifier les champs requis.");
      return;
    }

    fetch("/admin/streams/proxy_castr", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        stream_id: streamId,
        platform_id: platformId,
        action_type: actionType,
        show_id: showId,
        class_id: classId
      })
    })
      .then(res => {
        if (res.ok) {
          console.log(`✅ Action ${actionType} envoyée à Castr`);
          // ✅ Mise à jour immédiate du bloc de monitoring
          const monitoringBlock = card.querySelector(".monitoring");
          if (monitoringBlock) {
            const badge = monitoringBlock.querySelector(".badge");
            const small = monitoringBlock.querySelector("small");

            if (badge && small) {
              if (actionType === "start") {
                badge.textContent = "Actif";
                badge.className = "badge bg-success";
                small.textContent = "Dernier événement : stream lancé";
              } else if (actionType === "stop") {
                badge.textContent = "Inactif";
                badge.className = "badge bg-secondary";
                small.textContent = "Dernier événement : stream arrêté";
              }
            }
          }
          refreshActiveStreams();

        } else {
          alert(`❌ Erreur Castr: ${res.status}`);
        }
      })
      .catch(err => {
        console.error("❌ Erreur réseau Castr:", err);
        alert("Erreur réseau lors de l’appel Castr.io");
      });
  }

  const refreshBtn = document.querySelector("[data-action='castr#refresh']");
  if (refreshBtn) {
    refreshBtn.addEventListener("click", refreshActiveStreams);
  }

  function refreshActiveStreams() {
    const container = document.querySelector("#castr-streams");
    if (!container) return;

    container.innerHTML = "<p class='text-muted'>Chargement des streams...</p>";

    fetch("/admin/streams/active")
      .then(res => res.text())
      .then(html => {
        container.innerHTML = html;
        container.querySelectorAll("[data-action='castr#stop']").forEach(button => {
          button.addEventListener("click", handleStartStopStream);
        });
      })
      .catch(err => {
        console.error("❌ Erreur chargement streams actifs:", err);
        container.innerHTML = "<p class='text-danger'>Erreur de chargement</p>";
      });
  }

  function updateMonitoringStatus(classId, showId, container) {
    fetch(`/admin/streams/active`)
      .then(res => res.text())
      .then(html => {
        const tempDiv = document.createElement("div");
        tempDiv.innerHTML = html;
        const selector = `[data-class-id="${classId}"][data-show-id="${showId}"]`;
        const match = tempDiv.querySelector(selector);

        console.log("🔍 Recherche de :", selector, "→ trouvé :", !!match);

        const badge = container.querySelector(".status-badge");
        const eventLabel = container.querySelector(".last-event");

        if (!badge || !eventLabel) return;

        if (match) {
          badge.textContent = "Actif";
          badge.className = "badge bg-success";
          eventLabel.textContent = `Dernier événement : stream lancé`;
        } else {
          badge.textContent = "Inactif";
          badge.className = "badge bg-secondary";
          eventLabel.textContent = "Dernier événement : -";
        }
      })
      .catch(err => {
        console.warn("❌ Erreur lors de la récupération des streams actifs :", err);
      });
  }

  // Mise à jour sur changement d’épreuve
  const classSelects = document.querySelectorAll("[data-castr-target='classSelect']");
  classSelects.forEach((classSelect) => {
    classSelect.addEventListener("change", function () {
      const card = this.closest("[data-controller~='castr']");
      const monitoringBlock = card.querySelector(".monitoring");
      const classId = this.value;
      const showId = card?.dataset.providerId; // 🔁 Corrigé ici
      const streamSelect = card.querySelector("[data-castr-target='streams']");

      if (monitoringBlock && classId && showId && streamSelect?.value) {
        updateMonitoringStatus(classId, showId, monitoringBlock);
      }
    });
  });

  // Initialisation au chargement
  document.querySelectorAll("[data-controller~='castr']").forEach(card => {
    const classSelect = card.querySelector("[data-castr-target='classSelect']");
    const classId = classSelect?.value;
    const showId = card.dataset.providerId; // 🔁 Corrigé ici
    const monitoringBlock = card.querySelector(".monitoring");

    if (monitoringBlock && classId && showId) {
      updateMonitoringStatus(classId, showId, monitoringBlock);
    }
  });
});
