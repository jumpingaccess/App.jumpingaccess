document.addEventListener("turbo:load", function () {
  console.log("✅ startlist_controller connecté (version JS vanilla)");
  document.querySelectorAll("form[data-controller='startlist']").forEach(function (form) {
    const select = form.closest(".card-3d").querySelector("select[data-role='select-epreuve']");
    const hiddenClassId = form.querySelector("input[name='class_id']");
    const importButton = form.querySelector("[data-startlist-target='importButton']");
    const index = importButton.dataset.index;
    const statusZone = document.querySelector(`#startlist-status-${index}`);
    if (!statusZone) {
      console.warn("⛔️ Zone de statut introuvable pour index :", index);
      return;
    }

    if (!select || !hiddenClassId || !importButton) return;

    

    const update = () => {
      const selectedClassId = select.value;
      const meetingId = importButton.dataset.meetingId;
      const providerId = importButton.dataset.providerId;

      hiddenClassId.value = selectedClassId;
      hiddenClassId.name = "class_id";
      form.action = `/admin/meetings/${meetingId}/starts`;

      console.log(`🔍 Vérification : /admin/api/startlist_exists?provider_id=${providerId}&class_id=${selectedClassId}`);

      fetch(`/admin/api/startlist_exists?provider_id=${providerId}&class_id=${selectedClassId}`)
        .then(res => res.json())
        .then(data => {
          importButton.innerHTML = data.exists
            ? `<i class="fas fa-arrows-rotate me-1"></i> Update des départs`
            : `<i class="fas fa-download me-1"></i> Liste de départs`;

          statusZone.innerHTML = data.exists
            ? '<div class="text-success"><i class="fas fa-check-circle"></i> Liste de départs importée</div>'
            : '<div class="text-danger"><i class="fas fa-times-circle "></i> Liste de départs inexistante</div>';

        })
        .catch(err => {
          console.error("❌ Erreur lors de la vérification de la startlist :", err);
          statusZone.innerHTML = `<i class="fas fa-exclamation-circle text-warning me-1"></i> Erreur de vérification`;
        });
    };

    const onSubmit = (event) => {
      if (!hiddenClassId.value) {
        event.preventDefault();
        alert("Veuillez sélectionner une épreuve avant d'importer la startlist.");
      }
    };

    select.addEventListener("change", update);
    form.addEventListener("submit", onSubmit);

    update();
  });
});
