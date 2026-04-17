# Viajemos

Plataforma de viajes compartidos pensada para Argentina y LATAM. Conecta conductores que tienen lugares disponibles en sus viajes con pasajeros que buscan llegar al mismo destino, de forma simple, directa y sin intermediarios.

## ¿Qué es Viajemos?

Los conductores publican sus viajes indicando origen, destino, fecha, precio por asiento y preferencias (mascotas, búsqueda a domicilio, etc.). Los pasajeros buscan viajes por ruta y fecha, envían solicitudes y coordinan directamente con el conductor a través del chat integrado. Ambos roles conviven en la misma cuenta: el usuario puede alternar entre conductor y pasajero con un solo tap.

**Funcionalidades principales:**

- Publicación y gestión de viajes (hasta 3 activos simultáneos)
- Búsqueda de viajes con filtros por origen, destino, fecha y precio
- Sistema de solicitudes y aceptación de pasajeros
- Chat en tiempo real entre conductor y pasajero
- Invitaciones de conductor a pasajero
- Historial completo de viajes realizados y activos
- Calificaciones mutuas al finalizar un viaje
- Perfiles con bio, redes sociales y vehículos registrados
- Alertas de viaje para pasajeros que buscan rutas frecuentes
- Notificaciones en tiempo real mediante badges en la navegación

## Tecnologías

| Capa | Tecnología |
|---|---|
| Frontend | Flutter (Dart) |
| Estado | Riverpod |
| Backend / Base de datos | Supabase (PostgreSQL) |
| Autenticación | Supabase Auth |
| Tiempo real | Supabase Realtime (WebSockets) |
| Navegación | GoRouter |
| Mapas | flutter\_map + OpenStreetMap |
| Imágenes cacheadas | cached\_network\_image |
| Fuentes | Google Fonts |

## Estructura del proyecto

```
lib/
├── app.dart                  # Router principal (GoRouter)
├── core/
│   ├── providers/            # Providers globales (rol, badges)
│   └── theme/                # Colores y estilos
├── features/
│   ├── auth/                 # Login y registro
│   ├── driver/               # Crear viaje, mapa, vehículos
│   ├── passenger/            # Búsqueda y solicitudes
│   ├── chats/                # Chat en tiempo real
│   ├── history/              # Historial y viajes activos
│   └── profile/              # Perfil de usuario
└── shared/
    ├── widgets/              # Componentes reutilizables
    └── services/             # Servicios (búsqueda de ciudades, etc.)
```
