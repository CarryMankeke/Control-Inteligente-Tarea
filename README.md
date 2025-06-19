# PP2 – Adaptive Control Quadcopter

**Author:** Camilo Andrés Soto Villegas  
**Program:** Civil Mechatronic Engineering, USACH  
**Course:** Intelligent Control (Prof. Sabzalian)

## 📂 Estructura del Proyecto

pp2/
├─ main/                           ← Carpeta raíz del proyecto MATLAB
│  ├─ pp2.prj                      ← MATLAB Project (gestión de paths)
│  ├─ startup.m                    ← Inicializa paths al abrir el proyecto
│  ├─ config.m                     ← Parámetros globales y rutas
│  ├─ main.m                       ← Orquestador principal
│  ├─ scripts/                     ← Scripts de flujo (run_*.m)
│  │   ├─ run_preprocess.m
│  │   ├─ run_train_narx.m
│  │   ├─ run_tune_mrac.m
│  │   └─ run_simulation.m
│  ├─ functions/                   ← Funciones modulares
│  │   ├─ crear_quadrotorData.m
│  │   ├─ bloque1_preproceso.m
│  │   ├─ bloque2_narx_train.m
│  │   ├─ bloque3_generar_referencia.m
│  │   ├─ bloque4_init_mrac_eta_por_canal.m
│  │   ├─ bloque5_simulacion_lazo_cerrado.m
│  │   └─ bloque6_plot_resultados.m
│  ├─ data/
│  │   ├─ raw/                     ← Datos originales (Git-ignored)
│  │   └─ processed/               ← .mat intermedios (Git-ignored)
│  └─ results/
│      ├─ log/                     ← Guardado de métricas (Git-ignored)
│      └─ figures/                 ← Gráficos exportados (Git-ignored)
└─ .gitignore

Flujo de Trabajo:

1. Abrir pp2.prj en MATLAB → se ejecuta startup.m.
2. En Command Window:
   main  % Ejecuta preprocesamiento, entrenamiento, tuning y simulación
3. Los datos intermedios quedan en data/processed/, y los logs/figuras en results/.
