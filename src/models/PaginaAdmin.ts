export type PaginaAdmin = 'inicio' | 'citas' | 'ordenes' | 'catalogo' | 'detalle'

export type PaginaNavegacion = Exclude<PaginaAdmin, 'detalle'>