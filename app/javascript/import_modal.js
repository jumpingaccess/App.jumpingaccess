document.addEventListener("turbo:load", function () {
  document.querySelectorAll("[data-import-url]").forEach(button => {
    button.addEventListener("click", function (e) {
      e.preventDefault();

      const url = this.dataset.importUrl;
      const modalEl = document.getElementById("importProgressModal");
      const progressBar = document.getElementById("importProgressBar");
      const modal = new bootstrap.Modal(modalEl);

      progressBar.style.width = "0%";
      modal.show();

      let progress = 0;
      const interval = setInterval(() => {
        if (progress < 95) {
          progress += Math.random() * 5;
          progressBar.style.width = `${Math.min(progress, 95)}%`;
        }
      }, 150);

        fetch(url, {
        headers: { "Accept": "text/html" } // ✅ on force text/html
        })
        .then(response => {
          clearInterval(interval);
          progressBar.style.width = "100%";
          setTimeout(() => {
            modal.hide();
            if (response.redirected) {
              window.location.href = response.url;
            }
          }, 500);
        })
        .catch(error => {
          clearInterval(interval);
          modal.hide();
          alert("Erreur pendant l'import");
        });
    });
  });
});
