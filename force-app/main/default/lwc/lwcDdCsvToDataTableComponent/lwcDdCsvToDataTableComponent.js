/**
 * @author : Sugan
 * @date : Nov 30th 2022
 * @decription : Controller for converting uploaded CSV and display it as a lightning data table
 */
 /********************
 *
 * Imports
 *
 *****************************************************************************************************************************/
import { LightningElement,api } from 'lwc';

export default class LwcDdCsvToDataTableComponent extends LightningElement {
  /*****************************************************************************************************************************
  *
  * Public Variables
  *
  *****************************************************************************************************************************/
  @api tableData;
  @api uploadmsg;

  /*****************************************************************************************************************************
  *
  * Non public Variables
  *
  *****************************************************************************************************************************/
  columns;

/*****************************************************************************************************************************
  *
  * Event Handlers
  *
  *****************************************************************************************************************************/
  handleFileUpload(event) {
    const files = event.detail.files;

    if (files.length > 0) {
      const file = files[0];

      // start reading the uploaded csv file
      this.read(file);
    }
  }
/*****************************************************************************************************************************
  *
  * Logic / Helper methods
  *
  *****************************************************************************************************************************/
/**
 * @decription a method to read the contents of the uploaded csv file
 * @param   {file} param1 - uploaded file
 */
async read(file) {
    try {
      const result = await this.load(file);

      // execute the logic for parsing the uploaded csv file
      this.parse(result);
    } catch (e) {
      this.error = e;
    }
  }
/**
 * @decription a method to load the contents of the csv file using the FileReader api
 * @param   {file} param1 - uploaded file
 */
  async load(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onload = () => {
        resolve(reader.result);
      };
      reader.onerror = () => {
        reject(reader.error);
      };
      reader.readAsText(file);
    });
  }
/**
 * @decription a method to convert csv data into columns and rows for the lightning table
 * @param   {file} param1 - uploaded file
 */
  parse(csv) {
    // parse the csv file and treat each line as one item of an array
    const lines = csv.split(/\r\n|\n/);

    // parse the first line containing the csv column headers
    const headers = lines[0].split(',').map(element => {
      return element.trim();
    });

    // iterate through csv headers and transform them to column format supported by the datatable
    this.columns = headers.map((header) => {
      return { label: header, fieldName: header };
    });

    const data = [];

    // iterate through csv file rows and transform them to format supported by the datatable
    lines.forEach((line, i) => {
      if (i === 0) return;

      const obj = {};
      const currentline = line.split(',');

      for (let j = 0; j < headers.length; j++) {
        obj[headers[j]] = currentline[j];
      }

      data.push(obj);
    });

    // assign the converted csv data for the lightning datatable
    this.tableData = data;
  }
}