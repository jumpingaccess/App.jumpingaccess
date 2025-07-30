document.addEventListener("turbo:load", function () {
  console.log("✅ results_controller connecté (version JS vanilla)");

  document.querySelectorAll("form[id^='results-form-']").forEach(function (form) {
    const importButton = form.querySelector("[data-results-target='importButton']");
    const hiddenClassId = form.querySelector("input[name='class_id']");
    const index = importButton?.dataset.resultsIndex;

    const card = form.closest(".card-3d");
    const select = card?.querySelector("select[data-role='select-epreuve']");
    const statusZone = document.querySelector(`#results-status-${index}`);

    if (!form || !select || !hiddenClassId || !importButton || !statusZone) {
      console.warn("⛔️ Élément manquant pour index :", index);
      return;
    }

    const update = () => {
      const classId = select.value;
      const meetingId = importButton.dataset.meetingId;
      const providerId = importButton.dataset.providerId;

      if (!classId) return;

      hiddenClassId.value = classId;
      hiddenClassId.name = "class_id";
      form.action = `/admin/meetings/${meetingId}/results`;

      console.log(`📡 Vérification des résultats : /admin/api/results_exists?provider_id=${providerId}&class_id=${classId}`);

      fetch(`/admin/api/results_exists?provider_id=${providerId}&class_id=${classId}`)
        .then(res => res.json())
        .then(data => {
          statusZone.innerHTML = ""; // reset

          importButton.innerHTML = data.exists
          ? `<i class="fas fa-rotate me-1"></i> Update des résultats`
          : `<i class="fas fa-flag-checkered me-1"></i> Résultats`;
        
          statusZone.innerHTML = data.exists
          ?`<div class="text-success"><i class="fas fa-circle-check"></i> Résultats importés</div>`
          :`<div class="text-danger"><i class="fas fa-circle-xmark"></i> Résultats non importés</div>`;

    
        })
        .catch(err => {
          console.error("❌ Erreur API résultats :", err);
          statusZone.innerHTML = `<div class="text-warning"><i class="fas fa-triangle-exclamation"></i> Erreur API</div>`;
        });
    };

    const onSubmit = (event) => {
      if (!hiddenClassId.value) {
        event.preventDefault();
        alert("Veuillez sélectionner une épreuve avant d'importer les résultats.");
      }
    };

    select.addEventListener("change", update);
    form.addEventListener("submit", onSubmit);

    update(); // Initial load
  });
});
