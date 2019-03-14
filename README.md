# UnitSubclassify

My GUI for sub-classification of single units by cell-type, working on data stored in my [MultipleUnits/SingleUnit](https://github.com/edmerix/NeuroClass) objects. [Screenshots below](#screenshots).

It is semi-automatic, making use of the mean-autocorrelation lag (within 100 ms) of each unit (_AC lag_), the spike full-width at half-maximum (_FWHM_), delay from the spike valley to its following peak (_VtoP_), and the firing rate (_FR_).

You can set it to use any combination of these metrics for the automatic clustering (by default it uses all), and the plots simultaneously show the overall clustering results, and the clustering results when using just pairs of metrics.

Note that I remain skeptical about cell-type subclassifications in (human) neocortical recordings, as a major component of traditional classification is the spike shape – a feature which is heavily biased by the electrode tip's position on the cell's axo-dendritic axis [(Gold _et al_., 2006)](https://www.ncbi.nlm.nih.gov/pubmed/16467426). This relationship tends to automatically separate units by cell type in regions such as the hippocampus with its neat layers, just by their position relative to the recording electrode, whereas the neocortex is a bit less neatly structured...

That said, there have been some convincing subclassifications in human neocortical recordings that show physiologically plausible activity by cell type [(Peyrache _et al_., 2012)](https://www.ncbi.nlm.nih.gov/pubmed/22307639).

<sub><sup>(Also, a subset of pyramidal cells have been shown to have spike half-widths that are typically thought of as a feature of fast-spiking interneurons [(Vigneswaran _et al_., 2011)](https://www.ncbi.nlm.nih.gov/pubmed/21976508), however this may be limited to the relatively rare Betz cells in M1.)</sup></sub>

## Dependencies

It is designed to be used with my [MultipleUnits/SingleUnit](https://github.com/edmerix/NeuroClass) objects, though the data structure could easily be mimicked without using those classes.

Beyond that, it depends on 3 (fairly standard) Matlab toolboxes:
- Stats
- Curve fitting
- Signal processing

## Usage

```Matlab
% where data = %MultipleUnits instance%

app = UnitSubclassify(data,'setting_name','setting_value');

```
__Settings are provided in name, value pairs:__


| Setting      | Description                                                                                 |         Default value         |
|--------------|---------------------------------------------------------------------------------------------|:-----------------------------:|
| ClusterWith  | Which metrics to use for clustering (cell array)                                            | {'AC lag','FR','VtoP','FWHM'} |
| Fullscreen   | Start fullscreen (bool)                                                                     |             false             |
| Height       | Starting height of window (px)                                                              |              1440             |
| Width        | Starting width of window (px)                                                               |              900              |
| Debugging    | Whether to show debugging messages (bool)                                                   |             false             |
| Smoothing    | Whether to smooth the broadband waveforms (bool)                                            |              true             |
| SmoothFactor | What factor to smooth with, if smoothing (double)                                           |              0.15             |
| Uprate       | Multiple of original sampling frequency to interpolate up to (double)                       |               4               |
| JitterWidth  | Window in which true spike trough can be searched for when aligning (ms)                    |              0.1              |
| Pre          | Time to keep before the spike trough (ms)                                                   |               2               |
| Post         | Time to keep after the spike trough (ms)                                                    |               2               |
| MaxACLag     | Period over which the mean autocorrelation lag is calculated (s)                            |              0.1              |
| Fieldname    | Name of the wideband spikes stored (if using SingleUnit object, cannot be altered) (string) |           'wideband'          |
| Keypoint     | Data point where the spike trough is roughly anticipated to be (int)                        |               90              |

## Screenshots

![Screenshot of UnitSubclassify on a putative interneuron](Screenshots/putative_interneuron.png?raw=true "A putative fast-spiking interneuron")

![Screenshot of UnitSubclassify on a putative pyramidal cell](Screenshots/putative_pyramidal_cell.png?raw=true "A putative regular-spiking pyramidal cell (more accurately: a putative not-FS-interneuron)")
