# CLAUDE.md - Data and Creature Content

Data files define game truth. Creature identity, species-specific DNA, bond/eat meaning, reward weights, and song pressure must stay coherent.

- Preserve stable IDs and resource paths; do not rename IDs casually.
- Check runtime consumers before changing schemas or key names.
- Keep creature/support effects species-specific rather than generic stat soup.
- Use `validate_data.bat` after content changes and `validate_project.bat` when imports/resources are involved.
