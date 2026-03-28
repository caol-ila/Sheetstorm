/// Routes for GEMA feature
/// DO NOT modify app_router.dart - define feature routes here

const gemaRoutes = {
  'list': '/kapelle/:kapelleId/gema-meldungen',
  'detail': '/kapelle/:kapelleId/gema-meldungen/:reportId',
  'export': '/kapelle/:kapelleId/gema-meldungen/:reportId/export',
};
